@description('location for the IT VM')
param location string = resourceGroup().location

@description('Resource Group for the IT spoke VNet')
param vnetResourceGroup string ='RG-LayiCorp-Network'

@description('name of the IT VM')
param vmName string 

@description('Admin username for the VM')
param adminUsername string

@secure()
@description('Admin password for the VM')
param adminPassword string

@description('IT Spoke VNet name')
param vnetName string

@description('Subnet name in the spoke for this VM')
param subnetName string = 'frontend'

@description('VM size')
param vmSize string = 'Standard_B2s'

@description('Windows Server SKU')
param windowsSku string = '2019-Datacenter'

var nsgName = '${vmName}-nsg'
var nicName = '${vmName}-nic'

//
//Refrencing existing IT Spoke VNet + Subnet
//
resource vnet 'Microsoft.Network/virtualNetworks@2022-09-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  parent: vnet
  name: subnetName
}

// 
// NSG for the VM (Restricting RDP access to only Azure Bastion)
//

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-From-Bastion'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'AzureCloud'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

//
// Network Interface for the VM (private only - no public IP)
//

resource nic 'Microsoft.Network/networkInterfaces@2022-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id 
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

//
// IT Virtual Machine
//

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
          }
      }
   }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
