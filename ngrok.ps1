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
    [int]$SleepInterval = 5
)

function Get-NgrokUrl
{
    param (
        [string]$NgrokApiUrl = $NgrokApiUrl
    )
    try
    {
        Write-Host "Fetching ngrok tunnels from $NgrokApiUrl/$TunnelEndpoint..."
        $ngrokTunnels = Invoke-RestMethod -Uri "$NgrokApiUrl/$TunnelEndpoint" -Method Get -ErrorAction Stop
        $ngrokUrl = $ngrokTunnels.tunnels[0].public_url
        Write-Host "ngrok URL: $ngrokUrl"
        return $ngrokUrl
    }
    catch
    {
        Write-Host "Failed to retrieve ngrok URL: $_"
        throw $_
    }
}

function Update-BotServiceConfig
{
    param (
        [string]$SubscriptionId,
        [string]$ResourceGroupName,
        [string]$BotServiceName,
        [string]$NewUrl
    )
    try
    {
        if (-not (Get-Module -Name Az) -or -not (Get-Module -Name Az.BotService))
        {
            Write-Host "Importing Az module..."
            Import-Module Az -ErrorAction Stop -Force -NoClobber -Scope Global
            Write-Host "Importing Az Bot module..."
            Import-Module Az.BotService -ErrorAction Stop -Force -NoClobber -Scope Global
        }
        try
        {
            Write-Host "Connecting to Azure account using service principal..."
            Connect-AzAccount -Tenant $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop -NoTypeInformation
        }
        catch
        {
            Write-Host "Failed to connect using service principal. Attempting to connect to Azure account interactively..."
            Connect-AzAccount -Tenant $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop -UseDeviceAuthentication -Force
        }
        Write-Host "Setting Azure context to subscription $SubscriptionId"
        Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop -Force -Name "AzureCloud" -TenantId $TenantId
        try
        {
            $botService = Get-AzBotService -ResourceGroupName $ResourceGroupName -Name $BotServiceName -ErrorAction Stop
        }
        catch
        {
            Write-Host "Error retrieving or outputting Bot Service configuration: $_"
            throw $_
        }

        if ($botService)
        {
            Write-Host "Updating MessagingEndpoint to $NewUrl"
            Update-AzBotService -ResourceGroupName $ResourceGroupName -Name $BotServiceName -ErrorAction Stop -Endpoint $NewUrl
            return $oldUrl
        }
        else
        {
            Write-Host "Bot service not found"
            return $null
        }
    }
    catch
    {
        Write-Host "Failed to update Bot Service configuration: $_"
        throw $_
    }
}

function Stop-Ngrok
{
    try
    {
        $appService = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
        $urlbase = $appService.DefaultHostName
        Write-Host "Resetting MessagingEndpoint to https://$urlbase/$Endpoint"
        Update-AzBotService -ResourceGroupName $ResourceGroupName -Name $AppServiceName -ErrorAction Stop -Endpoint "https://$urlbase/$Endpoint"
        Write-Host "Bot Service configuration reset."
    }
    catch
    {
        Write-Host "Failed to reset Bot Service configuration: $_"
    }

    try
    {

        Write-Host "Stopping ngrok..."
        Stop-Process -Id $ngrokProcess.Id -Force -ErrorAction SilentlyContinue
        Write-Host "ngrok stopped."
    }
    catch
    {
        Write-Host "Failed to stop ngrok: $_"
        throw $_
    }

}

try
{
    Clear-Host
    Write-Host "Starting ngrok..."
    $ngrokProcess = Start-Process -FilePath $NgrokPath -ArgumentList "http", "$LocalHost", "--host-header=$HostHeader" -PassThru -ErrorAction Stop
    Write-Host "Waiting for ngrok to initialize..."
    $ngrokInitialized = $false
    $timeout = 0
    while (-not $ngrokInitialized -and $timeout -lt $MaxTimeout)
    {
        try
        {
            $ngrokUrl = Get-NgrokUrl  -ErrorAction Stop
            Write-Host "ngrok is ready. URL: $ngrokUrl"
            $ngrokInitialized = $true
        }
        catch
        {
            Write-Host "ngrok not yet ready. Waiting... $timeout of $MaxTimeout seconds elapsed."
            Start-Sleep -Seconds $SleepInterval
            $timeout += $SleepInterval
        }
    }
    if (-not $ngrokInitialized)
    {
        throw "Timeout while waiting for ngrok to initialize."
    }
    Write-Host "Updating Bot Service configuration..."
    Update-BotServiceConfig -SubscriptionId $AzureSubscriptionId -ResourceGroupName $ResourceGroupName -BotServiceName $AppServiceName -NewUrl "$ngrokUrl/$Endpoint"
    Write-Host "New Messaging Endpoint URL: $ngrokUrl/$Endpoint"
    Write-Host "Script execution completed successfully."
    Write-Host "Press any key to stop ngrok and exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host "Stopping ngrok..."
}
catch
{
    Write-Host "Script encountered an error: $_"
    if ($ngrokProcess -ne $null)
    {
        Stop-Ngrok
    }
}
finally
{
    if ($ngrokProcess -ne $null)
    {
        Stop-Ngrok
    }
}
