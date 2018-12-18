<#
.SYNOPSIS 
    This sample automation function reads a message from an Azure storage queue that contains the
    resource id of a VM to start.
    It then starts the VM.
    
    
.DESCRIPTION
    This sample automation function reads a message from an Azure storage queue that contains the
    resource id of a VM to start.
    It then starts the VM.

.PARAMETER QueueItem
    The message in the queue that is read.

.PARAMETER TriggerMetadata
    Required. Information about what triggered the function.

.NOTES
    AUTHOR: Eamon O'Reilly
    RELEASE: December 14th, 2018
    LASTEDIT: December 14th, 2018
        - Updated

#>

# Input bindings are passed in via param block.
param([string] $QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Information ("Reading VM Id from queue and starting the VM : $QueueItem")

if ($null -ne $Env:MSI_ENDPOINT)
{
    Write-Information ("Authenticating with MSI as we are running within Azure with managed identity enabled")
    $TokenAuthURI = $env:MSI_ENDPOINT + "?resource=https://management.azure.com/&api-version=2017-09-01"
    $TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI

    # Get subscription id from the website owner name environment variables and authenticate to Azure
    $Website_owner_name = $env:WEBSITE_OWNER_NAME
    $SubscriptionId = $Website_owner_name.Substring(0,$Website_owner_name.IndexOf('+'))
    $AppName = $env:APPSETTING_WEBSITE_SITE_NAME
    Login-AzAccount -SubscriptionId $SubscriptionId -AccessToken $TokenResponse.access_token `
                        -AccountId $AppName | Write-Information  
}

# Start the VM
Get-AzResource -Id $QueueItem | Start-AzVM
