# LayiCorp Cloud Governance and Landing Zone

## Overview

This project implements an Azure Landing Zone with real governance, secure networking, and controlled workload deployment. It is built using Azure Bicep, Azure Policy, and PowerShell automation for RBAC audits.

The environment is designed to look and behave like a real enterprise platform:

This project demonstrates both Phase 1 (network foundation) and Phase 2 (workload onboarding & governance), while keeping the README focused on the final integrated landing zone rather than the step-by-step learning sequence.

- Hub and spoke network architecture  
- Centralized firewall and shared services  
- Departmental spokes (IT, HR, SM)  
- Tagging and security enforcement through Azure Policy  
- Workload VM onboarding into a governed spoke  
- Backup and RBAC audit automation

The landing zone enforces security and operational standards from the platform layer downward, ensuring that any workload deployed into the environment automatically inherits governance, segmentation, and access control.


---

## Architecture

The platform follows a hub and spoke topology. The hub hosts shared security services. Each spoke represents a department with its own address space and subnets.


Each spoke can scale independently, but all inspections, routing, and shared services remain centralized in the hub, which mirrors Microsoft's Cloud Adoption Framework landing zone standards.

```mermaid
flowchart LR

    subgraph Hub["Hub VNet (Shared Services)"]
        FW["Azure Firewall"]
    end

    subgraph ITSpoke["IT Spoke VNet"]
        ITFE["Frontend Subnet"]
        ITBE["Backend Subnet"]
        ITDB["Database Subnet"]
        VM["Workload VM (vm-it-app01)"]
    end

    subgraph HR["HR Spoke VNet"]
        HRFE["Frontend Subnet"]
        HRBE["Backend Subnet"]
        HRDB["Database Subnet"]
    end

    subgraph SM["SM Spoke VNet"]
        SMFE["Frontend Subnet"]
        SMBE["Backend Subnet"]
        SMDB["Database Subnet"]
    end

    ITFE --> VM
    VM --> ITBE
    ITBE --> ITDB

    Hub <--> ITSpoke
    Hub <--> HR
    Hub <--> SM
 ```
The hub-and-spoke architecture was selected because it centralizes security, routing, and shared services in the hub, while keeping each department isolated within its own spoke. This aligns with enterprise best practices for multi-team or multi-tenant environments.

This provides:

- Isolation between departments

- A central choke point for security and inspection

- Clear pathways for east-west and north-south traffic
---



##  Network Foundation

Networking is deployed using Bicep templates located in infra/networking.
The network architecture serves as the backbone of the landing zone. It ensures segmentation of workloads, centralized security inspection, and consistent routing through the hub. This structure limits lateral movement, ensures clean separation of duties across departments, and enables predictable routing through the firewall for inspection and logging.

### Typical structure:

```
infra/
  networking/
    hub.bicep
    spoke-hr.bicep
    spoke-it.bicep
    spoke-sm.bicep
    peerings.bicep
    modules/
      vnet.bicep
      nsg.bicep
      subnet.bicep
      firewall.bicep
  parameters/
    hub.parameters.json
    spoke-hr.parameters.json
    spoke-it.parameters.json
    spoke-sm.parameters.json
```
The hub deployment is performed first to establish shared services such as Azure Firewall. Each spoke is then deployed independently and peered back to the hub to maintain isolation between HR, IT, and SM workloads.

The networking deployment is responsible for:

- Hub virtual network

- IT, HR and SM spoke virtual networks

- Subnets for frontend, backend and database

- VNet peerings between hub and spokes

- Azure Firewall in the hub

This matches common Azure landing zone patterns and can be reused in other subscriptions or environments.

## Workload Deployment

The IT department has a workload VM that is deployed into the IT spoke using Bicep.

### Example structure:
```
infra/
  workload/
    it-vm.bicep
    it-vm.parameters.json
```
The VM has:

- Private IP only

- Network interface in the IT spoke frontend subnet

- NSG that allows RDP only from Azure Bastion

- No internet facing RDP or SSH

- Credentials passed in as parameters

This workload deployment pattern becomes the blueprint for all future applications entering the platform, ensuring consistent security posture and centralized governance.

## Governance

Governance is applied after the network foundation has been deployed. Applying governance after the foundation is deployed is intentional for this project. It allows the environment to display non-compliant resources for demonstration and audit purposes, which is useful in interviews, presentations, and educational scenarios. In a real production landing zone, these policies would typically be applied before workload deployment to block violations early.

### Tag enforcement

The following tags are required on resources. Deployments are denied if they are missing or empty:

- Owner

- Environment

- CostCenter

### Network and security controls

-  NSG rules that expose RDP, SSH or WinRM (ports 3389, 22, 5985, 5986) to the internet are denied.

- Public IP usage is restricted to approved services such as Firewall, Bastion, VPN Gateway, Load Balancer and Application Gateway.

- VM NICs cannot receive public IP addresses unless explicitly allowed by policy.

###   Resource groups and resources are audited for missing tags

These policies ensure that the landing zone consistently applies metadata, restricts open management ports, and gives clear visibility into non compliant resources.

Once applied, these policies enforce operational discipline across the environment.

---


##  Backup and Recovery

A Recovery Services Vault is configured to protect the IT workload VM.

The configuration includes:

- Daily backup policy

- Workload VM registered as a protected item

- At least one successful backup job

- Evidence that restore is possible if needed

This shows that the platform is not just deployed, but also operationally ready.

##  RBAC Audit Automation

Role-based access control is reviewed and exported using a PowerShell-based audit script. This ensures that privileged access is documented and that no excessive permissions are granted unintentionally.

The file scripts/rbac-audits.ps1 runs an RBAC audit over the subscription.

It produces:

- A CSV of all role assignments

- A CSV of high privilege roles such as Owner, Contributor and Security Admin

- A CSV of direct user assignments

- A CSV of guest user assignments

- Exports are written into the exports folder and the folder is excluded from git to avoid leaking any tenant specific data.

This provides governance teams with a repeatable method to review access and supports compliance audits.

## Repository Structure

```
infra/
  networking/
    hub.bicep
    peerings.bicep
    spoke-hr.bicep
    spoke-it.bicep
    spoke-sm.bicep
    modules/
      firewall.bicep
      nsg.bicep
      subnet.bicep
      vnet.bicep

  parameters/
    hub.parameters.json
    spoke-hr.parameters.json
    spoke-it.parameters.json
    spoke-sm.parameters.json
    
  workloads/
    it-vm.bicep
    it-vm.parameters.json

policy/
  require-tag-owner.json
  require-tag-environment.json
  require-tag-costcenter.json
  deny-open-nsg.json
  audit-rg-missing-tags.json
  initiative-baseline.json

scripts/
  rbac-audits.ps1

exports/        (gitignored)
README.md
```
This structure separates governance, networking, and workload concerns, allowing each layer to evolve independently. It also mirrors enterprise patterns where teams maintain separate modules but deploy through standardized pipelines. Each folder is designed to be reusable, modular, and easy to integrate into CI/CD workflows.

The intent is clear separation between infrastructure, governance and automation.

##    Deployment

Deployments follow a staged approach that reflects the actual sequence used in this project. Networking and workloads are deployed first, and governance is applied afterwards so that non-compliant resources can still be deployed for demonstration purposes.


### 1. Create resource groups

```
az group create --name RG-LayiCorp-Network --location westeurope
az group create --name RG-LayiCorp-IT --location westeurope
```

### 2. Deploy the hub VNet and firewall

```
az deployment group create \
  --resource-group RG-LayiCorp-Network \
  --template-file ./infra/networking/hub.bicep \
  --parameters @./infra/parameters/hub.parameters.json
  ```
### 3. Deploy the three spoke VNets
IT spoke:
```
az deployment group create \
  --resource-group RG-LayiCorp-Network \
  --template-file ./infra/networking/spoke-it.bicep \
  --parameters @./infra/parameters/spoke-it.parameters.json
  ```

HR spoke:
```
az deployment group create \
  --resource-group RG-LayiCorp-Network \
  --template-file ./infra/networking/spoke-hr.bicep \
  --parameters @./infra/parameters/spoke-hr.parameters.json
  ```

SM spoke:
```
az deployment group create \
  --resource-group RG-LayiCorp-Network \
  --template-file ./infra/networking/spoke-sm.bicep \
  --parameters @./infra/parameters/spoke-sm.parameters.json
  ```
### 4. Deploy VNet peerings between hub and spokes
```
az deployment group create \
  --resource-group RG-LayiCorp-Network \
  --template-file ./infra/networking/peerings.bicep
  ```
After the hub and spokes are deployed, you should see:
- 1 hub virtual network with firewall and shared subnets
- 3 spoke VNets (HR, IT, SM)
- Successful VNet peering connections (spoke to hub only)
- Subnets matching the department-specific IP ranges

### 5. Deploy the IT workload VM into the IT spoke
```
az deployment group create \
  --resource-group RG-LayiCorp-IT \
  --template-file ./infra/workloads/it-vm.bicep \
  --parameters @./infra/workloads/it-vm.parameters.json
  ```
This drops vm-it-app01 into the vnet-spoke-it-layicorp frontend subnet with a private NIC and NSG that only allows RDP from Bastion.

### 6. Create the policy initiative from the repository definition

```
az policy set-definition create \
  --name layicorp-baseline-governance \
  --definition ./policy/initiative-baseline.json
```
Then assign it at the subscription scope:

```
az policy assignment create \
  --name layicorp-baseline-governance-assignment \
  --policy-set-definition layicorp-baseline-governance \
  --scope /subscriptions/<SUBSCRIPTION_ID>
  ```


### 7. Run RBAC audit script

From the repo root:

```
./scripts/rbac-audits.ps1 -SubscriptionId <SUBSCRIPTION_ID>
```

This writes CSVs into the exports folder.

##  Validation

Validation steps prove that the landing zone is not only deployed but also governed, secured, and fully operational.

Evidence collected for this project includes:

- Resource group overview

- Hub and spoke VNet configuration

- Azure Firewall deployment

- VNet peering state

- Policy initiative and policy definition views

- Policy compliance view showing non-compliant resources (expected due to deployment order)

- VM overview and networking showing no public IP

- NSG inbound rules that prove management ports are restricted

- Recovery Services Vault and backup status for the VM

- Cost analysis grouped by resource group

- Terminal output from the RBAC audit script and exported CSV files

These validation points show that the platform is deployed, governed and operational, not just theoretical.

##  Summary

LayiCorp Cloud Governance and Landing Zone demonstrates how to build a realistic Azure platform that combines:

- Hub and spoke networking

- Azure Firewall and NSGs

- Azure Policy for tagging and security

- Secure workload onboarding using Bicep

- Backup through Recovery Services Vault

- RBAC audit automation with PowerShell

This project delivers a secure, governed, and scalable Azure landing zone that reflects real enterprise patterns. It combines policy enforcement, network segmentation, centralized security, workload isolation, and role auditing into a single, cohesive deployment framework. The result is a production-ready foundation capable of supporting growth, compliance requirements, and future automation.

