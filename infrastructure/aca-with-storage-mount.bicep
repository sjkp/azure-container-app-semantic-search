

param name string
param location string
param lawClientId string
@secure()
param lawClientSecret string

@description('Number of CPU cores the container can use. Can be with a maximum of two decimals.')
param cpuCore string = '0.25'

@description('Amount of memory (in gibibytes, GiB) allocated to the container up to 4GiB. Can be with a maximum of two decimals. Ratio with CPU cores must be equal to 2.')
param memorySize string = '0.5'

@description('Minimum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplicas int = 0

@description('Maximum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplicas int = 1

param storageAccountName string
@secure()
param storageAccountKey string

param fileshareName string

resource env 'Microsoft.App/managedEnvironments@2022-03-01'= {
  name: 'containerapp-env-${name}'
  location: location
  properties: {   
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: lawClientId
        sharedKey: lawClientSecret
      }
    }    
  }
}

var storageName = 'acastorage'

resource envStorage 'Microsoft.App/managedEnvironments/storages@2022-03-01' = {
  parent: env
  name: storageName
  properties: {
    azureFile: {
      accessMode: 'ReadWrite'
      accountKey: storageAccountKey
      accountName: storageAccountName
      shareName: fileshareName
    }
  }
}

// qdrant container
resource containerApp 'Microsoft.App/containerApps@2023-11-02-preview' = {
  name: 'container-app-${name}-qdrant'
  dependsOn: [
    envStorage
  ]
  location: location  
  properties: {
    managedEnvironmentId: env.id    
    configuration: {      
      ingress: {
        additionalPortMappings: [
          {
            exposedPort: 6334
            external: true
            targetPort: 6334
          }
        ]
        external: true
        targetPort: 6333
        exposedPort: 6333
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
          name: 'container-app-${name}-qdrant'
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
  name: 'container-app-${name}-embed'
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
          name: 'container-app-${name}-embed'
          image: 'sjkp/blitz-embed:v1'          
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }          
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }    
  }
}
