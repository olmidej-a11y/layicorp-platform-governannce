param firewallName string
param vnetId string
param firewallPublicIPName string

resource fireWallPip 'Microsoft.Network/publicIPAddresses@2022-07-01' = { 
  name: firewallPublicIPName
  location: resourceGroup().location
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
  properties:{ 
    publicIPAllocationMethod: 'Static'
  }
}
resource firewall 'Microsoft.Network/azureFirewalls@2022-07-01' = { 
  name: firewallName
  location: resourceGroup().location
  properties: { 
    ipConfigurations: [
      {
      name: 'fw-ipconfig'
      properties: {
        subnet: { 
           id: '${vnetId}/subnets/AzureFirewallSubnet'
    }
    publicIPAddress:{ 
      id: fireWallPip.id
    }
   }  
  }
  ]
 }
}


