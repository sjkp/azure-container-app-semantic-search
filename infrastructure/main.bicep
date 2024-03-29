targetScope = 'subscription'

param appName string
param location string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${appName}'
  location: location
}

var storageAccountName = 'st${appName}'
var fileshareName = 'data'

module storage './storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: storageAccountName
    location: location
  }
  scope: rg
}

module fileshare './storage-file-share.bicep' = {
  name: 'fileshare'
  dependsOn: [
    storage
  ]
  params: {
    storageAccountName: storageAccountName
    fileshareName: fileshareName
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


module aca 'aca-with-storage-mount.bicep' = {
  scope: rg
  name: 'azurecontainer'
  params: {
    lawname: logs.outputs.name
    location: location
    name: appName
    fileshareName: fileshareName
    storageAccountName: storage.outputs.storageAccountName
  }
}
