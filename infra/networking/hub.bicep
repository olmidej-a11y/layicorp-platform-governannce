param hubVnetName string
param addressSpace array

//Subnet definitions for hub
param hubSubnets array

//Firewall configuration
@description('Deploy Azure Firewall into the hub')
param deployFirewall bool = true

@description('Name of Azure Firewall')
param firewallName string 

@description('Name of Public IP for Azure Firewall')
param firewallPublicIPName string 

module hubVnet './modules/vnet.bicep' ={
  name:'hub-vnet'
  params: {
    vnetName: hubVnetName
    addressSpace: addressSpace
    subnets: hubSubnets
  }
}


module hubFirewall './modules/firewall.bicep' = if (deployFirewall) {
  name: 'hub-firewall'
  params: {
    firewallName: firewallName
    vnetId: hubVnet.outputs.vnetId
    firewallPublicIPName: firewallPublicIPName
  }
}
output hubVnetId string = hubVnet.outputs.vnetId
