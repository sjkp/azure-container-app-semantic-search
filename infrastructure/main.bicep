targetScope = 'subscription'

param appName string
param location string
param containerImage string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${appName}'
  location: location
}

var storageAccountName = 'st${appName}'

module storage './storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: storageAccountName
    location: location
  }
  scope: rg
}

module logs 'logs.bicep' = {
  scope: rg
  name: 'logs'
  params: {
    location: location 
    name: 'logs-${appName}'
  }
}

module keyvault 'keyvault.bicep' = {
  scope: rg
  name: 'keyvault'  
  params: {
    name: 'kv-${appName}'
    location: location
    principalIds: []
    secrets: [
      {
        name: 'AzureStorageConnectionString'
        value: storage.outputs.connectionString
      }
    ]
  }
}

module aca 'aca.bicep' = {
  scope: rg
  name: 'azurecontainer'
  params: {
    lawClientId: logs.outputs.clientId
    lawClientSecret: logs.outputs.clientSecret
    location: location
    name: appName
    containerImage: containerImage
  }
}
