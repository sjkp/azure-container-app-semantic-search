

param name string
param location string
param lawname string

@description('Number of CPU cores the container can use. Can be with a maximum of two decimals.')
param cpuCore string = '1'

@description('Amount of memory (in gibibytes, GiB) allocated to the container up to 4GiB. Can be with a maximum of two decimals. Ratio with CPU cores must be equal to 2.')
param memorySize string = '2'

@description('Minimum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplicas int = 0

@description('Maximum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplicas int = 1

param storageAccountName string

param fileshareName string

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: lawname
}

resource env 'Microsoft.App/managedEnvironments@2022-03-01'= {
  name: 'containerapp-env-${name}'
  location: location
  properties: {   
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: law.properties.customerId
        sharedKey: law.listKeys().primarySharedKey
      }
    }    
  }
}

var storageName = 'acastorage'
var apikey = guid(resourceGroup().id)

resource stg 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: storageAccountName
}

resource envStorage 'Microsoft.App/managedEnvironments/storages@2022-03-01' = {
  parent: env
  name: storageName
  properties: {
    azureFile: {
      accessMode: 'ReadWrite'
      accountKey: stg.listKeys().keys[0].value
      accountName: storageAccountName
      shareName: fileshareName
    }
  }
}

// qdrant container
resource containerApp 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: 'ca-${name}-qdrant'
  dependsOn: [
    envStorage
  ]
  location: location  
  properties: {
    managedEnvironmentId: env.id    
    configuration: {      
      ingress: {        
        external: true
        targetPort: 6333
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100            
          }
        ]
      }
    }
    template: {
      volumes: [
        {
          name: 'externalstorage'
          storageName: storageName
          storageType: 'AzureFile'          
        }
      ]      
      containers: [
        {          
          name: 'ca-${name}-qdrant'
          image: 'qdrant/qdrant:latest'          
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
          volumeMounts: [
            {
              mountPath: '/qdrant/storage'
              volumeName: 'externalstorage'
            }
          ]
          env: [
            {
              name: 'QDRANT__SERVICE__API_KEY'
              value: apikey
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }    
  }
}


resource containerApp2 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: 'ca-${name}-embed'
  dependsOn: [
    envStorage
  ]
  location: location  
  properties: {
    managedEnvironmentId: env.id    
    configuration: {      
      ingress: {       
        external: true
        targetPort: 8080        
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100            
          }
        ]
      }
    }
    template: {           
      containers: [
        {          
          name: 'ca-${name}-embed'
          image: 'ghcr.io/sjkp/blitz-embed:latest'          
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
          env: [
            {
              name: 'API_KEY'
              value: apikey
            }
          ]          
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }    
  }
}
