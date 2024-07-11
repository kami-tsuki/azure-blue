# Azure Blue v1.2
# Description: This script starts ngrok, retrieves the ngrok URL, updates the Bot Service configuration with the ngrok URL, and stops ngrok.
# Parameters:
#   - NgrokPath: The path to the ngrok executable.
#   - LocalHost: The local host URL to tunnel.
#   - AzureSubscriptionId: The Azure subscription ID.
#   - ResourceGroupName: The Azure resource group name.
#   - AppServiceName: The Azure App Service name.
#   - TenantId: The Azure tenant ID.
#   - Endpoint: The Bot Service endpoint to update.
#   - TunnelEndpoint: The ngrok API endpoint to retrieve the tunnel URL.
#   - NgrokApiUrl: The ngrok API URL.
#   - HostHeader: The host header to use when starting ngrok.
#   - MaxTimeout: The maximum time to wait for ngrok to initialize.
#   - SleepInterval: The interval to wait between ngrok initialization checks.
#   - ImportScope: The scope to import the Az module.
#   - ResetBotEndpoint: A flag to reset the Bot Service endpoint.
#   - ResetNgrok: A flag to reset ngrok.
#   - DefaultProtocol: The protocol to use for the default endpoint.
# Usage: .\ngrok.ps1 -NgrokPath "C:\path\to\ngrok.exe" -LocalHost "http://localhost:5000" -AzureSubscriptionId "subscriptionId" -ResourceGroupName "resourceGroupName" -AppServiceName "appServiceName" -TenantId "tenantId"
# Author: Tsuki Kami

param (
    [string]$NgrokPath,
    [string]$LocalHost,
    [string]$AzureSubscriptionId,
    [string]$ResourceGroupName,
    [string]$AppServiceName,
    [string]$TenantId,
    [string]$Endpoint = "api/messages",
    [string]$TunnelEndpoint = "api/tunnels",
    [string]$NgrokApiUrl = "http://localhost:4040",
    [string]$HostHeader = "localhost:5000",
    [int]$MaxTimeout = 120,
    [int]$SleepInterval = 5,
    [string]$ImportScope = "Global",
    [bool]$ResetBotEndpoint = $true,
    [bool]$ResetNgrok = $true,
    [string]$DefaultProtocol = "https"
)

function Import-AzModules {
    param (
        [string]$Scope = $ImportScope
    )
    $azModule = Get-Module -ListAvailable -Name Az
    $azBotServiceModule = Get-Module -ListAvailable -Name Az.BotService

    if ($azModule -and -not (Get-Module -Name Az)) {
        Write-Host "Importing Az module..."
        Import-Module Az -ErrorAction Stop -Force -NoClobber -Scope $Scope
    }

    if ($azBotServiceModule -and -not (Get-Module -Name Az.BotService)) {
        Write-Host "Importing Az BotService module..."
        Import-Module Az.BotService -ErrorAction Stop -Force -NoClobber -Scope $Scope
    }
}

function Get-NgrokUrl {
    param (
        [string]$ApiUrl = $NgrokApiUrl
    )
    try {
        Write-Host "Fetching ngrok tunnels from $ApiUrl/$TunnelEndpoint..."
        $ngrokTunnels = Invoke-RestMethod -Uri "$ApiUrl/$TunnelEndpoint" -Method Get -ErrorAction Stop
        $ngrokUrl = $ngrokTunnels.tunnels[0].public_url
        Write-Host "ngrok URL: $ngrokUrl"
        return $ngrokUrl
    } catch {
        Write-Host "Failed to retrieve ngrok URL: $_"
        throw $_
    }
}

function Update-BotServiceConfig {
    param (
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [string]$BotServiceName,
        [string]$NewUrl
    )
    try {
        Import-AzModules -Scope $ImportScope

        Write-Host "Connecting to Azure account..."
        Connect-AzAccount -Tenant $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop

        Write-Host "Setting Azure context to subscription $SubscriptionId"
        Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop

        Write-Host "Retrieving Bot Service..."
        $botService = Get-AzBotService -ResourceGroupName $ResourceGroupName -Name $BotServiceName -ErrorAction Stop

        Write-Host "Updating MessagingEndpoint to $NewUrl"
        Update-AzBotService -ResourceGroupName $ResourceGroupName -Name $BotServiceName -ErrorAction Stop -Endpoint $NewUrl
    } catch {
        Write-Host "Failed to update Bot Service configuration: $_"
        throw $_
    }
}

function Reset-BotServiceConfig {
    try {
        $appService = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -ErrorAction Stop
        $urlbase = $appService.DefaultHostName
        $defaultUrl = "$DefaultProtocol"+"://$urlbase/$Endpoint"
        Write-Host "Resetting MessagingEndpoint to $defaultUrl"
        Update-AzBotService -ResourceGroupName $ResourceGroupName -Name $AppServiceName -ErrorAction Stop -Endpoint $defaultUrl
        Write-Host "Bot Service configuration reset."
    } catch {
        Write-Host "Failed to reset Bot Service configuration: $_"
    }
}

function Stop-Ngrok {
    try {
        Write-Host "Stopping ngrok..."
        Stop-Process -Id $ngrokProcess.Id -Force -ErrorAction SilentlyContinue
        Write-Host "ngrok stopped."
    } catch {
        Write-Host "Failed to stop ngrok: $_"
    }
}

function Stop-NgrokAndReset {
    param (
        [bool]$ResetBot = $ResetBotEndpoint,
        [bool]$ResetNgrok = $ResetNgrok
    )
    if ($ResetBot) {
        Reset-BotServiceConfig
    }
    if ($ResetNgrok) {
        Stop-Ngrok
    }
}

function Start-AzureBlue {
    try {
        Clear-Host
        Write-Host "Starting ngrok..."
        $ngrokProcess = Start-Process -FilePath $NgrokPath -ArgumentList "http", "$LocalHost", "--host-header=$HostHeader" -PassThru -ErrorAction Stop

        Write-Host "Waiting for ngrok to initialize..."
        $ngrokInitialized = $false
        $timeout = 0
        while (-not $ngrokInitialized -and $timeout -lt $MaxTimeout) {
            try {
                $ngrokUrl = Get-NgrokUrl -ApiUrl $NgrokApiUrl
                Write-Host "ngrok is ready. URL: $ngrokUrl"
                $ngrokInitialized = $true
            } catch {
                Write-Host "ngrok not yet ready. Waiting... $timeout of $MaxTimeout seconds elapsed."
                Start-Sleep -Seconds $SleepInterval
                $timeout += $SleepInterval
            }
        }

        if (-not $ngrokInitialized) {
            throw "Timeout while waiting for ngrok to initialize."
        }

        Write-Host "Updating Bot Service configuration..."
        Update-BotServiceConfig -SubscriptionId $AzureSubscriptionId -ResourceGroupName $ResourceGroupName -BotServiceName $AppServiceName -NewUrl "$ngrokUrl/$Endpoint"

        Write-Host "New Messaging Endpoint URL: $ngrokUrl/$Endpoint"
        Write-Host "Script execution completed successfully."
        Write-Host "Press any key to stop ngrok and exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        Write-Host "Script encountered an error: $_"
        if ($ngrokProcess -ne $null) {
            Stop-NgrokAndReset -ResetBot $ResetBotEndpoint -ResetNgrok $ResetNgrok
        }
    } finally {
        if ($ngrokProcess -ne $null) {
            Stop-NgrokAndReset -ResetBot $ResetBotEndpoint -ResetNgrok $ResetNgrok
        }
        Write-Host "Good bye!"
    }
}

Start-AzureBlue
