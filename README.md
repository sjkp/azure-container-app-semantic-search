# Azure Container Apps - Semantic Search Backend

Use this template to create an Azure Container App Semantic Search backend using [qdrant](https://qdrant.tech) as vector database and https://github.com/sjkp/blitz-embed/tree/master as embedding endpoint. 

Besides Azure Container Apps, the template deploys a storage account and log analytics workspace. 

Things you want to modify
| Location | Usage |
| - | - |
|.github/workflows/deploy.yaml| For the github action to work you must set the following Github action secrets: `AZURE_CREDENTIALS` (see below how to create a value, it is the full json response of the `az ad sp` command that you should use)  `AZURE_SUBSCRIPTION` (this should contain the subscription Id). 
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


## Testing  
You can use the included `test.http` file to test the endpoints. Replace the apiKey and baseUri and baseUriEmbedding with your endpoints. The API key can be found in the environment variables section of the embedding container app, as it is generated dynamically during the deployment.