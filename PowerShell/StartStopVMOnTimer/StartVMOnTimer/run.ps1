# Input bindings are passed in via param block.
param($Timer)

# Specify the VMs that you want to start. Modify or comment out below based on which VMs to check.
$VMResourceGroupName = "Contoso"
#$VMName = "ContosoVM1"
#$TagName = "AutomaticallyStart"

# Stop on error
$ErrorActionPreference = 'stop'
try 
{
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
    $ProcessedVMs = @()

    foreach ($VirtualMachine in $VMs)
    {
        $VM = Get-AzVM -ResourceGroupName $VirtualMachine.ResourceGroupName -Name $VirtualMachine.Name -Status
        if ($VM.Statuses.Code[1] -eq 'PowerState/deallocated')
        {
            Write-Information ("Starting VM " + $VirtualMachine.Id)
            $ProcessedVMs += $VirtualMachine.Id
            Start-AzVM -Id $VirtualMachine.Id -AsJob | Write-Information
        }
    }
    # Sleep here a few seconds to make sure that each VM command gets processed before the script ends
    if ($ProcessedVMs.Count -gt 0)
    {
        Start-Sleep 30
    } 

    # Associate values to output bindings by calling 'Push-OutputBinding'. Name of output is Response as defined in function.json
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = '200'
        Body = $ProcessedVMs
    })
}
catch
{
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = '500'
        Body = $_.Exception.Message
    })
}
