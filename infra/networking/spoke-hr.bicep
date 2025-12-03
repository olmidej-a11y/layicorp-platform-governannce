param location string = resourceGroup().location
param spokeVnetName string
param addressSpace array
param spokeSubnets array

module spokeVnet 'modules/vnet.bicep' = {
  name: 'spoke-hr-vnet'
  params: {
    vnetName: spokeVnetName
    addressSpace: addressSpace 
    subnets: spokeSubnets
  }
}
output spokeVnetId string = spokeVnet.outputs.vnetId
