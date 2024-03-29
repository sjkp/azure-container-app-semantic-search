

param name string
param location string
param lawClientId string
param lawClientSecret string

@description('Specifies the docker container image to deploy.')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Specifies the container port.')
param targetPort int = 80

@description('Number of CPU cores the container can use. Can be with a maximum of two decimals.')
param cpuCore string = '0.5'

@description('Amount of memory (in gibibytes, GiB) allocated to the container up to 4GiB. Can be with a maximum of two decimals. Ratio with CPU cores must be equal to 2.')
param memorySize string = '1'

@description('Minimum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param minReplicas int = 1

@description('Maximum number of replicas that will be deployed')
@minValue(0)
@maxValue(25)
param maxReplicas int = 1



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


resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'container-app-${name}'
  location: location  
  properties: {
    managedEnvironmentId: env.id    
    configuration: {      
      ingress: {
        external: true
        targetPort: targetPort
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
          name: 'container-app-${name}'
          image: containerImage          
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
