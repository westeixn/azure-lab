# Azure Infrastructure Lab — Modular Terraform & Automated Bootstrapping

![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?style=flat&logo=terraform)
![Microsoft Azure](https://img.shields.io/badge/Microsoft%20Azure-Cloud-0078D4?style=flat&logo=microsoftazure)
![Linux](https://img.shields.io/badge/Ubuntu-Cloud--Init-E95420?style=flat&logo=ubuntu)
[![Terraform CI](https://github.com/westeixn/azure-lab/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/westeixn/azure-lab/actions/workflows/terraform-ci.yml)

## Overview

This repository demonstrates an end-to-end **Infrastructure as Code (IaC)** deployment on **Microsoft Azure** using **Terraform**. 

Designed with an enterprise infrastructure and network security mindset, this project translates traditional on-premises principles—such as perimeter firewall segmentation, centralized configuration policies, and least-privilege access—into declarative, reusable, and automated cloud infrastructure.

## Scope & Architectural Trade-offs

This repository is a **sandbox and Proof of Concept (PoC)** designed to demonstrate modular Infrastructure as Code (IaC) patterns, remote state management, and automated server bootstrapping on Microsoft Azure.

To keep testing fast and cost-effective, the following intentional trade-offs were made compared to a production environment:

- **Network Exposure:** The virtual machine uses a direct Public IP for immediate validation. In production, compute instances would reside in private subnets accessed exclusively via **Azure Bastion** or a corporate VPN.
- **Authentication:** Password authentication is disabled in favor of RSA SSH keys for lab convenience. Production baselines enforce centralized key management via **Azure Key Vault**.
- **Traffic Encryption:** Port `80` (HTTP) is open to validate the `cloud-init` Nginx deployment. Production workloads would enforce **HTTPS/TLS** behind an Azure Application Gateway or Load Balancer with WAF policies.

---

## Architecture & Key Features

### 1. Modular Network Design (`modules/network`)
Instead of a monolithic configuration, the networking layer is isolated into a dedicated, reusable Terraform module. This decouples the shared network foundation from specific compute workloads, adhering to the **DRY (Don't Repeat Yourself)** principle:
* **Virtual Network (VNet):** Isolated private address space (`vnet-corporativa`).
* **Subnet:** Segmented workload tier (`subnet-servidores`).
* **Network Security Group (NSG):** Subnet-level traffic filtering (`nsg-servidores`) enforced via explicit subnet association.

### 2. Perimeter Security Hardening
Applying zero-trust network perimeter practices to cloud resources:
* **Restricted SSH Access (TCP/22):** Inbound SSH is strictly locked down to a single authorized public IP (`var.allowed_ssh_ip` in CIDR `/32` notation), eliminating exposure to `0.0.0.0/0`.
* **Controlled Web Ingress (TCP/80):** Inbound HTTP traffic is explicitly permitted to serve the web application.
* **No Hardcoded Secrets or IPs:** Environment-specific parameters (such as authorized IPs and credentials) omit default values in `variables.tf` and are excluded from version control via `.gitignore` (`*.tfvars`).

### 3. Zero-Touch Bootstrapping (`cloud-init`)
To eliminate manual post-deployment configuration, the Ubuntu Linux Virtual Machine (`vm-ubuntu-lab`) leverages Azure's `custom_data` attribute to execute a `cloud-init` script on first boot:
* Updates OS package repositories automatically.
* Installs, enables, and starts the **Nginx** web server.
* Deploys a custom landing page immediately available via the VM's public IP address.

### 4. Remote State Management & State Locking
Terraform state is stored remotely using the `azurerm` backend (`Azure Blob Storage`) rather than locally:
* **Single Source of Truth:** Keeps sensitive infrastructure metadata off local workstations.
* **Concurrency Protection:** Leverages Azure Blob Storage native lease mechanisms for **State Locking**, preventing state corruption during concurrent operations.

### 5. FinOps & Resource Tagging Governance
All compatible top-level resources across the root configuration and network module receive standardized metadata (`project`, `environment`, `managed_by`) centralized via Terraform `locals` and passed as a `map(string)`—enforcing cost traceability and the DRY principle.

### 6. Continuous Integration (GitHub Actions)
An automated CI workflow (`.github/workflows/terraform-ci.yml`) runs on every `push` and `pull_request`, enforcing code formatting (`terraform fmt -check -recursive`) and static configuration validation (`terraform validate` with `-backend=false`).

---

## Repository Structure

```text
azure-lab/
├── .github/
│   └── workflows/
│       └── terraform-ci.yml   # Automated fmt and validate CI pipeline
├── modules/
│   └── network/
│       ├── main.tf            # VNet, Subnet, NSG rules, and Subnet-NSG association
│       ├── variables.tf       # Input contract (CIDRs, allowed_ssh_ip, tags map)
│       └── outputs.tf         # Exports vnet_id and subnet_id to root resources
├── .gitignore                 # Excludes .terraform/, state files, and *.tfvars
├── locals.tf                  # Centralized governance tags (Single Source of Truth)
├── main.tf                    # Resource Group, network module call, Public IP, NIC, and VM
├── variables.tf               # Root input variables (location, CIDRs, SSH key path, VM specs)
├── outputs.tf                 # Exposes VNet ID, Subnet ID, Private IP, and Public IP
└── README.md                  # Project documentation
```

---

## Prerequisites

* [Terraform](https://developer.hashicorp.com/terraform/downloads) (`>= 1.5.0`)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) authenticated (`az login`)
* An active Microsoft Azure subscription
* An existing Azure Storage Account and Container configured for the `azurerm` remote state backend

---

## Usage & Deployment

### 1. Clone the Repository
```bash
git clone https://github.com/westeixn/azure-lab.git
cd azure-lab
```

### 2. Initialize Terraform
Downloads the `azurerm` provider, initializes the remote state backend, and registers the local `./modules/network` module:
```bash
terraform init
```

### 3. Review the Execution Plan
Provide your current public IP in `/32` CIDR format when prompted (or via a local, git-ignored `terraform.tfvars` file):
```bash
terraform plan
```

### 4. Apply the Infrastructure
```bash
terraform apply
```
When prompted for `var.allowed_ssh_ip`, enter your public IP (e.g., `203.0.113.10/32`).

### 5. Verify the Deployment
Once `terraform apply` completes, copy the `ip_publico_da_nic` output value and open it in your browser:
```text
http://<PUBLIC_IP>
```
You should see the custom Nginx page provisioned automatically via `cloud-init`.

### 6. Clean Up Resources
Destroy all lab resources to avoid unnecessary cloud costs (the remote state storage account remains intact):
```bash
terraform destroy
```

---

## Inputs & Outputs

### Key Root Input Variables
| Name | Description | Type | Sensitive |
| :--- | :--- | :--- | :---: |
| `location` | Azure region for resource deployment | `string` | No |
| `vnet_cidr` | Address space for the Virtual Network | `list(string)` | No |
| `subnet_cidr` | Address prefix for the servers subnet | `list(string)` | No |
| `allowed_ssh_ip` | Authorized public IPv4 CIDR (`/32`) for SSH ingress | `string` | No |
| `vm_size` | Azure Virtual Machine SKU | `string` | No |
| `username_vm` | Administrator username for the Linux VM | `string` | No |
| `ssh_public_key_path` | Local path to the RSA SSH public key | `string` | No |

### Outputs
| Name | Description |
| :--- | :--- |
| `vnet_id` | Resource ID of the provisioned Virtual Network |
| `subnet_id` | Resource ID of the provisioned Subnet |
| `ip_privado_da_nic` | Private IP address assigned to the VM network interface |
| `ip_publico_da_nic` | Public IP address assigned to access the web server |

---

## Author

**Weslley Negrão**  
IT Infrastructure Analyst transitioning into Cloud & DevOps Engineering | Focused on Microsoft Azure, Terraform (IaC), Network Security, and Automation.  
* LinkedIn: [linkedin.com/in/westeixn](https://www.linkedin.com/in/westeixn)
* GitHub: [github.com/westeixn](https://github.com/westeixn)