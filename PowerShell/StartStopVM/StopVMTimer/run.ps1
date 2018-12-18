<#
.SYNOPSIS 
    This sample automation function timer trigger can call the GetVMToStop function. You can configure
    the timer as needed. It is currently set to go off at 8pm and target the virtual machines
    defined in the JsonBody below. You can customize this as needed.

.DESCRIPTION
    This sample automation function timer trigger can call the GetVMToStop function. You can configure
    the timer as needed. It is currently set to go off at 8am and target the virtual machines
    defined in the JsonBody below. You can customize this as needed.

.PARAMETER Timer
    Required. Information about the Timer.

.NOTES
    AUTHOR: Eamon O'Reilly
    RELEASE: December 14th, 2018
    LASTEDIT: December 14th, 2018
        - Updated

#>

# Input bindings are passed in via param block.
param($Timer)

$FunctionName = "GetVMToStop"

# Modify these for specific requirements to find machines to stop
$JsonBody = @'
{
    "ResourceGroupName":  "contoso",
    "VMName": "Finance1",
    "Tag": "AutoStartStop"
}
'@

# Only run this in the service where Managed service identity is enabled
if ($null -ne $Env:MSI_ENDPOINT)
{
    Write-Information ("Authenticating with MSI as we are running within Azure with managed identity enabled")
    $TokenAuthURI = $env:MSI_ENDPOINT + "?resource=https://management.azure.com/&api-version=2017-09-01"
    $TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $TokenAuthURI
    
    # Get subscription id from the website owner name environment variables and authenticate to Azure
    $Website_Owner_Name = $env:WEBSITE_OWNER_NAME
    $SubscriptionId = $Website_Owner_Name.Substring(0,$Website_Owner_Name.IndexOf('+'))
    $AppName = $env:APPSETTING_WEBSITE_SITE_NAME
    Login-AzAccount -SubscriptionId $SubscriptionId -AccessToken $TokenResponse.access_token `
                        -AccountId $AppName | Write-Information
              
    # Get resource group the function is in.
    $ResourceGroupWithoutSubscriptionId = $Website_Owner_Name.Substring($SubscriptionId.Length+1)
    $ResourceGroup = $ResourceGroupWithoutSubscriptionId.Substring(0,$ResourceGroupWithoutSubscriptionId.IndexOf('-'))

    # Set up auth header so we can make REST calls to function app
    $RequestHeader = @{
        "Authorization" = "Bearer $($TokenResponse.access_token)"
    }

    # Get the url key for the function
    $FunctionKeys = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourceGroups/$($ResourceGroup)/providers/Microsoft.Web/sites/$($AppName)/hostruntime/admin/functions/$($FunctionName)/keys?api-version=2015-08-01"
    $FunctionCode = Invoke-RestMethod -Method Get -Headers $RequestHeader -Uri $FunctionKeys
    
    # Set the URL to the function
    $GetVMToStop = "https://$env:APPSETTING_WEBSITE_SITE_NAME.azurewebsites.net/api/$($FunctionName)?code=$($FunctionCode.keys.value)"
    
    # Stop all VMs in the resource group by calling the function with the body of VMs to look for
    Invoke-RestMethod $GetVMToStop -Method Post -Body $JsonBody
                
}


