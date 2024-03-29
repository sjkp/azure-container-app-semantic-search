# Azure Container Apps - Infrastructure Template 

Use this template to create an Azure Container App repository that configures an Azure environment ready for use for hosting docker containers. It uses the subscription deploy scope, so you need a service principal with access to the subscription where you want to deploy the resource group. 

Besides Azure Container Apps, it deploys a storage account and an Azure Key Vault, and log analytics workspace. 

Things you want to modify
| Location | Usage |
| - | - |
|.github/workflows/deploy.yaml| For the github action to work you must set the following Github action secrets: `AZURE_CREDENTIALS` (see below how to create a value, it is the full json response of the `az ad sp` command that you should use)  `AZURE_SUBSCRIPTION` (this should contain the subscription Id). *If you need an Azure Container App that uses an Azure file share mount you can use the template `main-with-storage.bicep` instead of just main in `deploy.yaml`*
| infrastructure/params.json | You can change the `location` of the resource group (all resource are deployed to same location) and the `appName` in here, `appName` is used to generate the name of all the resources and the resource group. You can also change which `containerImage` that you want deployed, it defaults to nginx |




## Manual Deployment
```
az deployment sub create --location northeurope --template-file infrastructure/main.bicep --parameters infrastructure/params.json
```


## Github Action Deployment

When generating your credentials (in this example we store in a secret named AZURE_CREDENTIALS) you will need to specify a scope at the subscription level.

```
az ad sp create-for-rbac --name "{sp-name}" --sdk-auth --role contributor --scopes /subscriptions/{subscription-id}
```
Note: the `sp-name` must be a subdomain of your tenant name, e.g. `ghaction.<your-tenant>.onmicrosoft.com`
