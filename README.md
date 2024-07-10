Azure Blue v1

---

# Azure Bot Service Ngrok Tunnel Configuration Script

This script sets up an Ngrok tunnel and updates the Azure Bot Service configuration with the new endpoint URL.

## Prerequisites

### 1. Install Azure PowerShell Modules

To manage Azure resources, you need to have the Azure PowerShell modules installed. You can install them using the following commands:

```powershell
Install-Module -Name Az -AllowClobber -Force
Install-Module -Name Az.BotService -AllowClobber -Force
```

> [official documentation](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?view=azps-12.1.0&tabs=powershell&pivots=windows-psgallery)

### 2. Install Ngrok

Download and install Ngrok from the [official website](https://ngrok.com/download). After installing, make sure the Ngrok executable is available in your system PATH or provide the full path to the executable.

## Setup

1. **Clone the repository or download the script file** to your local machine.
2. **Update the script parameters** with your specific values.

### Script Parameters

- `NgrokPath`: The file path to the Ngrok executable.
- `LocalHost`: The local host URL you want to expose via Ngrok (e.g., `localhost:3978`).
- `AzureSubscriptionId`: Your Azure Subscription ID.
- `ResourceGroupName`: The name of your Azure Resource Group.
- `AppServiceName`: The name of your Azure Bot Service.
- `TenantId`: Your Azure Active Directory Tenant ID.
- `Endpoint`: The endpoint path for your bot (default is `api/messages`).
- `TunnelEndpoint`: The Ngrok API endpoint to retrieve tunnels (default is `api/tunnels`).
- `NgrokApiUrl`: The URL for the Ngrok API (default is `http://localhost:4040`).
- `HostHeader`: The host header for Ngrok (default is `localhost:5000`).
- `MaxTimeout`: The maximum time to wait for Ngrok to initialize in seconds (default is `120`).
- `SleepInterval`: The interval between checks for Ngrok initialization in seconds (default is `5`).

## Execution

1. **Open PowerShell** and navigate to the directory containing the script.
2. **Execute the script** with the necessary parameters:

   ```powershell
   .\NgrokBotService.ps1 -NgrokPath "C:\path\to\ngrok.exe" -LocalHost "http://localhost:3978" -AzureSubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -AppServiceName "your-app-service-name" -TenantId "your-tenant-id"
   ```

## Process

### Step-by-Step Explanation

1. **Initialize Ngrok**:
    - The script starts Ngrok with the provided parameters to expose the local bot service.
    - It waits until Ngrok initializes and retrieves the public URL.

2. **Update Azure Bot Service Configuration**:
    - The script connects to Azure using the provided service principal or interactively if necessary.
    - It retrieves the current Bot Service configuration.
    - The MessagingEndpoint is updated to the new Ngrok URL.

3. **Script Execution Completion**:
    - Once the endpoint is updated, the script waits for a key press to stop Ngrok and reset the Bot Service configuration to its original state.

## Issues

### Possible Issues and Fixes

1. **Ngrok Fails to Start**:
    - Ensure that the Ngrok executable path is correct and Ngrok is properly installed.
    - Check for any other process that might be using the same port.

2. **Unable to Connect to Azure**:
    - Verify that the Azure PowerShell modules (`Az` and `Az.BotService`) are installed.
    - Check the provided `AzureSubscriptionId` and `TenantId` for correctness.
    - Ensure that your account has the necessary permissions to update the Bot Service configuration.

3. **Ngrok URL Retrieval Failure**:
    - Ensure that the Ngrok API URL is correct (`http://localhost:4040` by default).
    - Verify that Ngrok is running and accessible.

4. **Bot Service Configuration Update Fails**:
    - Check if the Bot Service name and Resource Group name are correct.
    - Ensure you have the right permissions to update the Bot Service configuration.

By following this guide, you should be able to set up and execute the script successfully, configuring your Azure Bot Service with a new Ngrok tunnel endpoint. If you encounter any issues, refer to the "Possible Issues and Fixes" section for troubleshooting steps.

---

Author: k**A**m**I**
