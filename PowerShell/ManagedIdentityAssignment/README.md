# Managed service identity for Azure Function applications
 Deploy an Azure function application with a managed service identity and assign this identity contributor access to a resource group or subscription so that it can manage resources there.

## Deploying the solution
 
## Prerequisites

Before running this sample, you must have the following:

+ Install [Azure Core Tools version 2.x](functions-run-local.md#v2).

+ Install the [Azure CLI]( /cli/azure/install-azure-cli).

+ Install the [Az PowerShell modules](https://www.powershellgallery.com/packages/Az/).


## Clone repository or download files to local machine

+ Change to the /PowerShell/ManagedIdentityAssignment directory.
+ Open up the azuredeploy.parameters.json and change them to be specific for the deployment. The default for functionAppTemplateURL is a sample function application available on github that sets up PowerShell on Linux dedicated.
+ The scope parameter can either be None, ResourceGroup, or Subscription and is used to assign contributor access for the function application at the desired scope.

## Deploy function application on Azure

+ Run the following command
```powershell
New-AzDeployment -TemplateFile .\azuredeploy.json -TemplateParameterFile .\azuredeploy.parameters.json -Location "West US 2" -Verbose
```
This should create a new resource group with a function application and assign the MSI contributor access to the resource group or subscription if specified.

## Test functions locally if using the sample StartStopVM
+ Change to the /PowerShell/StartStopVM directory.
+ Install the [Azure storage emulator](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-emulator) as this is used by the functions to store items in a storage queue.
+ Start the Azure storage emulator
+ Run "func init --worker-runtime powershell" to initialize the environment to PowerShell
+ Change the value in local.settings.json for "AzureWebJobsStorage" from "{AzureWebJobsStorage}" to "UseDevelopmentStorage=true"
+ Run "func extensions install" to register the bindings that are used by these functions.
+ Run "func start" to start a local powershell worker host
+ Open up another PowerShell terminal and run "Invoke-RestMethod 'http://localhost:7071/api/GetVMToStop?ResourceGroupName=contoso&VMName=Finance1' where contoso and Finance1 is the resource group and vm name of a VM running in Azure.
+ Switch back to the running PowerShell host and you should see details of the VM getting added to the queue "stopvm-queue-items" in the local storage emulator by the GetVMToStop function and then picked up by the ReadVMFromQueueAndStop function and the VM stopped.

## Upload functions to the function application
+ Modify the functions StartVMTimer and StopVMTimer with the ResourceGroupName, VMName, or Tag in the $JsonBody variable for the Azure VMs you want to target.
+ Modify the trigger time in the function.json for the StartVMTimer and StopVMTimer function for when you want the VMs to start and stop. Default is 8pm and 8am.
+ Run "func azure functionapp publish "FunctionAppName" --nozip" to publish the six functions to the function application created earlier replacing "FunctionAppName" with the function that was created.