# Azure Functions Hello World sample with embedded script code

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2feamonoreilly%2fAzureFunctions%2fmaster%2fPowerShell%2fHelloWorld%2fazuredeploy.json) 
<a href="http://armviz.io/#/?load=https%3a%2f%2fraw.githubusercontent.com%2feamonoreilly%2fAzureFunctions%2fmaster%2fPowerShell%2fHelloWorld%2fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This Azure Resource Manager template deploys a new function application and a HelloWorld function.

The code deployed is shown below:
```powershell
param($Request, $TriggerMetadata)

$ErrorActionPreference = 'stop'
# Write to the Azure Functions log stream.
Write-Information ("Starting function...") 

if ($null -ne $Env:MSI_ENDPOINT)
{
    Write-Information ("Authenticating with MSI as we are running within Azure with managed identity enabled")
    $TokenAuthURI = $env:MSI_ENDPOINT + "?resource=https://management.azure.com/&api-version=2017-09-01"
    $TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $TokenAuthURI
    
    # Get subscription id from the website owner name environment variables and authenticate to Azure
    $Website_owner_name = $env:WEBSITE_OWNER_NAME
    $SubscriptionId = $Website_owner_name.Substring(0,$Website_owner_name.IndexOf('+'))
    $AppName = $env:APPSETTING_WEBSITE_SITE_NAME
    Login-AzAccount -SubscriptionId $SubscriptionId -AccessToken $TokenResponse.access_token `
                    -AccountId $AppName | Write-Information
}

if ($Request.Method -eq "POST")
{
    Write-Information ("Post method used")
    Write-Information (ConvertTo-Json $Request.Body)    
}
else
{
    Write-Information ("Get method used")
    Write-Information (ConvertTo-Json $Request.Query)
}

# Write out all of the resources
Get-AzResource
```

## Template features

This template creates a dedicated linux function application with the following capabilities:
* MSI is enabled for the function application.
* MSI is granted contributor permission to the resource group the application is deployed.
* HelloWorld function is deployed using a httpTrigger binding.
