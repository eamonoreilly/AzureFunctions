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

# Start the VM
Get-AzResource -Id $QueueItem | Start-AzVM
