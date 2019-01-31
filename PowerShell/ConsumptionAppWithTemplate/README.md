# Azure Functions Hello World sample with embedded script code

[![Deploy to Azure](http://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2feamonoreilly%2fAzureFunctions%2fmaster%2fPowerShell%2fHelloWorld%2fazuredeploy.json) 
<a href="http://armviz.io/#/?load=https%3a%2f%2fraw.githubusercontent.com%2feamonoreilly%2fAzureFunctions%2fmaster%2fPowerShell%2fHelloWorld%2fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This Azure Resource Manager template deploys a new function application in consumption plan. It supports dotnet, node, java, or powershell runtime stacks.

## Template features

This template creates a windows consumption function application with the following capabilities:

* MSI is enabled for the function application.
* MSI is granted contributor permission to the resource group the application is deployed.
* Application insights is created in the specified location to help with monitoring / troubleshooting / insights.
