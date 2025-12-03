param hubVnetName string ='vnet-hub-layicorp'
param itSpokeVnetName string = 'vnet-spoke-it-layicorp'
param hrSpokeVnetName string = 'vnet-spoke-hr-layicorp'
param smSpokeVnetName string = 'vnet-spoke-sm-layicorp'

//Assume all Vnets are in the same RG For this deployment
//If creating across multiple RGs, add separate scope definitions

resource hubVnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: hubVnetName
}
resource itSpokeVnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: itSpokeVnetName
}
resource hrSpokeVnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: hrSpokeVnetName
}
resource smSpokeVnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: smSpokeVnetName
}

// Hub <-> IT 
resource hubToIt 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${hubVnet.name}/hub-to-it'
  properties: {
    remoteVirtualNetwork: { 
      id: resourceId('Microsoft.Network/virtualNetworks', itSpokeVnet.name)
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}


resource itToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${itSpokeVnetName}/it-to-hub'
  properties: {
    remoteVirtualNetwork: { 
      id: resourceId('Microsoft.Network/virtualNetworks', hubVnet.name)
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

//Hub <-> HR 
resource hubToHr 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${hubVnetName}/hub-to-hr'
  properties: {
    remoteVirtualNetwork: { 
      id: resourceId('Microsoft.Network/virtualNetworks', hrSpokeVnet.name)
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource hrToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${hrSpokeVnetName}/hr-to-hub'
  properties: {
    remoteVirtualNetwork: { 
      id: resourceId('Microsoft.Network/virtualNetworks', hubVnet.name)
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

//Hub <-> SM 
resource hubToSm 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${hubVnetName}/hub-to-sm'
  properties: {
    remoteVirtualNetwork: { 
      id: resourceId('Microsoft.Network/virtualNetworks', smSpokeVnet.name)
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource smToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-09-01' = {
  name: '${smSpokeVnetName}/sm-to-hub'
  properties: {
    remoteVirtualNetwork: { 
      id: resourceId('Microsoft.Network/virtualNetworks', hubVnet.name)
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
