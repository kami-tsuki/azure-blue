---

# Azure Blue v1.1

---

## Azure Bot Service Ngrok Tunnel Configuration Script

This script automates the process of starting an Ngrok tunnel, retrieving the Ngrok URL, updating the Azure Bot Service configuration with the new endpoint URL, and stopping Ngrok.

## Prerequisites

### 1. Install Azure PowerShell Modules

To manage Azure resources, you need to have the Azure PowerShell modules installed. You can install them using the following commands:

```powershell
Install-Module -Name Az -AllowClobber -Force
Install-Module -Name Az.BotService -AllowClobber -Force
```

For more details, refer to the [official documentation](https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?view=azps-12.1.0&tabs=powershell&pivots=windows-psgallery).

### 2. Install Ngrok

Download and install Ngrok from the [official website](https://ngrok.com/download). After installing, make sure the Ngrok executable is available in your system PATH or provide the full path to the executable.

## Setup

1. **Clone the repository or download the script file** to your local machine.
2. **Update the script parameters** with your specific values.

## Parameters

| Parameter            | Type      | Default Value         | Description                                                                 |
|----------------------|-----------|-----------------------|-----------------------------------------------------------------------------|
| `NgrokPath`          | string    |                       | The path to the Ngrok executable.                                           |
| `LocalHost`          | string    |                       | The local host URL to tunnel (e.g., `http://localhost:5000`).                |
| `AzureSubscriptionId`| string    |                       | The Azure subscription ID.                                                  |
| `ResourceGroupName`  | string    |                       | The Azure resource group name.                                              |
| `AppServiceName`     | string    |                       | The Azure App Service name.                                                 |
| `TenantId`           | string    |                       | The Azure tenant ID.                                                        |
| `Endpoint`           | string    | `api/messages`        | The Bot Service endpoint to update.                                         |
| `TunnelEndpoint`     | string    | `api/tunnels`         | The Ngrok API endpoint to retrieve the tunnel URL.                          |
| `NgrokApiUrl`        | string    | `http://localhost:4040`| The Ngrok API URL.                                                          |
| `HostHeader`         | string    | `localhost:5000`      | The host header to use when starting Ngrok.                                 |
| `MaxTimeout`         | int       | 120                   | The maximum time to wait for Ngrok to initialize.                           |
| `SleepInterval`      | int       | 5                     | The interval to wait between Ngrok initialization checks.                   |
| `ImportScope`        | string    | `Global`              | The scope to import the Az module.                                          |
| `ResetBotEndpoint`   | bool      | true                  | A flag to reset the Bot Service endpoint.                                   |
| `ResetNgrok`         | bool      | true                  | A flag to reset Ngrok.                                                      |
| `DefaultProtocol`    | string    | `https`               | The protocol to use for the default endpoint.                               |
| `Start`              | int       | 0                     | 0 or 1, if 1 is only starting, dont waits for reset, even on errors        |
| `Reset`              | int       | 0                     | 0 or 1, if 1 dont processes the start and just resets the url in bot (DONT stops Ngrok |

## Execution

1. **Open PowerShell** and navigate to the directory containing the script.
2. **Execute the script** with the necessary parameters:

   ```powershell
   .\AzureBlue.ps1 -NgrokPath "C:\path\to\ngrok.exe" -LocalHost "http://localhost:5000" -AzureSubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -AppServiceName "your-app-service-name" -TenantId "your-tenant-id"
   ```

   - To just start the program without the automated resetting:
   ```powershell
   .\AzureBlue.ps1 -NgrokPath "C:\path\to\ngrok.exe" -LocalHost "http://localhost:5000" -AzureSubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -AppServiceName "your-app-service-name" -TenantId "your-tenant-id -Start 1"
   ```

   - To only reset the program without starting:
   ```powershell
   .\AzureBlue.ps1 -NgrokPath "C:\path\to\ngrok.exe" -LocalHost "http://localhost:5000" -AzureSubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -AppServiceName "your-app-service-name" -TenantId "your-tenant-id -Reset 1"
   ```

   > Currently the Reset also needs some potential uneeded NGrok data, is planned to fix!

## Detailed Process

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

### Code Structure

- **Import-AzModules**: Ensures that the required Azure PowerShell modules are loaded.
- **Get-NgrokUrl**: Retrieves the public URL from the Ngrok API.
- **Update-BotServiceConfig**: Updates the Azure Bot Service configuration with the new Ngrok URL.
- **Reset-BotServiceConfig**: Resets the Bot Service endpoint to its original state.
- **Stop-Ngrok**: Stops the Ngrok process.
- **Stop-NgrokAndReset**: Stops Ngrok and optionally resets the Bot Service configuration.
- **Start-AzureBlue**: Main function that coordinates the script execution.

### Examples

1. **Starting the script**:

   ```powershell
   .\AzureBlue.ps1 -NgrokPath "C:\path\to\ngrok.exe" -LocalHost "http://localhost:5000" -AzureSubscriptionId "your-subscription-id" -ResourceGroupName "your-resource-group" -AppServiceName "your-app-service-name" -TenantId "your-tenant-id"
   ```

2. **Official Documentation References**:
    - [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-12.1.0)
    - [Ngrok](https://ngrok.com/docs)

### Troubleshooting

#### Possible Issues and Fixes

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

## Cleanup

### Deleting the Script

To delete the script and clean up:

1. **Stop any running instances of Ngrok** using the script.
2. **Delete the script file** from your local machine.
3. **Uninstall the Azure PowerShell modules** if they are no longer needed:

   ```powershell
   Uninstall-Module -Name Az -AllVersions -Force
   Uninstall-Module -Name Az.BotService -AllVersions -Force
   ```

By following this guide, you should be able to set up and execute the script successfully, configuring your Azure Bot Service with a new Ngrok tunnel endpoint. If you encounter any issues, refer to the "Possible Issues and Fixes" section for troubleshooting steps.

---

Author: Tsuki Kami

---
