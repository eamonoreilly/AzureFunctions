<#
.SYNOPSIS 
    This sample automation function gets a list of stopped VMs that should be started and adds them to an
    Azure storage queue so they can be processed and started reliably.
    
    This function takes input as either parameters on the URI or as a json body in a post request. The values
    of the input will take either the form:
    Get:
       # Start all VMs in the subscription
       Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart'

       # Start all VMs in the contoso resource group
       Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart?ResourceGroupName=contoso'

       # Start the VM finance in the resource group contoso
       Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart?ResourceGroupName=contoso&VMName=finance'

       # Start all VMs that have the tag of financemachines
       Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart?Tag=financemachines' 
    
    Post:
        $JsonBody = @'
        {
            "ResourceGroupName":  "contoso",
            "Tag": "financemachines"
        }
        '@

        # Start the VMs in resource group contoso with tag financemachines
        Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart' -Method Post -Body $JsonBody

.DESCRIPTION
    This sample automation function gets a list of stopped VMs that should be started and adds them to an
    Azure storage queue so they can be processed and started reliably.
    
    This function takes input as either parameters on the URI or as a json body in a post request. The values
    of the input will take either the form:
    Get:
       # Start all VMs in the subscription
       Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart'

       # Start all VMs in the contoso resource group
       Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart?ResourceGroupName=contoso'

       # Start the VM finance in the resource group contoso
       Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart?ResourceGroupName=contoso&VMName=finance'

       # Start all VMs that have the tag of financemachines
       Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart?Tag=financemachines' 
    
    Post:
        $JsonBody = @'
        {
            "ResourceGroupName":  "contoso",
            "Tag": "financemachines"
        }
        '@

        # Start the VMs in resource group contoso with tag financemachines
        Invoke-RestMethod 'http://localhost:7071/api/GetVMToStart' -Method Post -Body $JsonBody

    It is used in combination with the ReadVMFromQueueAndStart function that reads the VMs and starts them.
    It will by default leverage the Managed Service Identify of the function app to authenticate against
    the subscription / resoruce group / VM. You need to grant permission to the subscription / other resource
    groups if you are managing those VMs. By default, the MSI  is granted permission to the resource group
    that this function app is created in.

.PARAMETER Request
    The request body in json format that is sent into the function.

.PARAMETER TriggerMetadata
    Required. Information about what triggered the function.

.NOTES
    AUTHOR: Eamon O'Reilly
    RELEASE: December 14th, 2018
    LASTEDIT: December 14th, 2018
        - Updated

#>


# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
$ErrorActionPreference = 'stop'
try {
    # Write to the Azure Functions log stream.
    Write-Information ("Starting function GetVMToStart...") 

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
        $JsonBody = ConvertFrom-Json $Request.Body
        Write-Information $JsonBody
    
        $VMResourceGroupName = (ConvertFrom-Json $Request.Body).ResourceGroupName
        $VMName = (ConvertFrom-Json $Request.Body).VMName
        $TagName = (ConvertFrom-Json $Request.Body).Tag
        
    }
    else
    {
        # Get any input parameters
        $VMResourceGroupName = $Request.Query.ResourceGroupName
        $VMName = $Request.Query.VMName
        $TagName = $Request.Query.Tag
    }

    # Check for VM without resource group specified
    if  ($null -ne $VMName -and $null -eq $VMResourceGroupName)
    {
        throw "Resource group must not be empty if a VM is specified"
    }

    # Get a single vm, vms in a resource group, or all vms in the subscription
    if  ($null -ne $VMResourceGroupName -and $null -ne $VMName)
    {
        Write-Information ("Getting VM in resource group " + $VMResourceGroupName + " and VMName " + $VMName)
        $VMs = Get-AzVM -ResourceGroupName $VMResourceGroupName -Name $VMName
    }
    elseif ($null -ne $VMResourceGroupName)
    {
        Write-Information("Getting all VMs in resource group " + $VMResourceGroupName)
        $VMs = Get-AzVM -ResourceGroupName $VMResourceGroupName
    }
    else
    {
        Write-Information ("Getting all VMs in the subscription")
        $VMs = Get-AzVM
    }

    # Check if VM has the specified tag on it and filter to those.
    If ($null -ne $TagName)
    {
        $VMs = $VMs | Where-Object {$_.Tags.Keys -eq $TagName}
    }

    # Start the VM if it is deallocated
    $StoppedVMs = @()

    foreach ($VirtualMachine in $VMs)
    {
        Write-Information $VirtualMachine.Id
        $VM = Get-AzVM -ResourceGroupName $VirtualMachine.ResourceGroupName -Name $VirtualMachine.Name -Status
        if ($VM.Statuses.Code[1] -eq 'PowerState/deallocated')
        {
            $StoppedVMs += $VirtualMachine.Id
            # Add machine to start to Azure queue so it can be processed by the start vm function
        }
    }

    Push-OutputBinding -Name QueueItem -Value $StoppedVMs

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = 200
        Body = $StoppedVMs
    })
}
catch
{
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = "500"
        Body = $_.Exception.Message
    })
}
