param vnetName string
param addressSpace array
param subnets array


resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: vnetName
  location: resourceGroup().location
  properties: { 
    addressSpace: {
      addressPrefixes: addressSpace
    }
    subnets: [ for s in subnets: {
      name: s.name
      properties: {
        addressPrefix: s.prefix
      }
    }
  ]
  }
}
output vnetId string = vnet.id
