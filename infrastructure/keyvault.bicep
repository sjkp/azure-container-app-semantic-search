param name string
param principalIds array
param secrets array
param location string = resourceGroup().location

var accessPolicies = [for principalId in principalIds: {
  tenantId: subscription().tenantId
  objectId: principalId
  permissions: {
    keys: [
      'get'
      'list'
      'wrapKey'
      'unwrapKey'
    ]
    secrets: [
      'get'
      'list'
    ]
    certificates: []
  }
}]


resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  location: location
  name: name
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enablePurgeProtection: true
    enableSoftDelete: false
    accessPolicies: accessPolicies
  }
}

resource kvSecrets 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for secret in secrets: if(secret.value != 'empty-override') {
  dependsOn: [
    kv
  ]
  name: '${name}/${replace(secret.name,'_','')}'
  properties: {
    value: secret.value
    attributes: {
      enabled: true
    }
  }
}]
