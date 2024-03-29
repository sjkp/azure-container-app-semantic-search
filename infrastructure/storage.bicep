param storageAccountName string
param location string

resource stg 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(stg.id, stg.apiVersion).keys[0].value};EndpointSuffix=core.windows.net'
output storageAccountKey string = listKeys(stg.id, stg.apiVersion).keys[0].value

