## 🎯 Current Situation
- **Existing Infrastructure**: Manual creation (to be imported)
- **New Infrastructure**: Terraform creation
- **5 Environments**: dev, qa, uat, prod, dr
- **5 Subscriptions**: One per environment


### One Storage Account for ALL State Files

```
Storage Account: terraformstatefiles

Container: terraform-tfstate
├── dev-existing.terraform.tfstate 
├── dev-new.terraform.tfstate
├── qa-existing.terraform.tfstate
├── qa-new.terraform.tfstate
├── uat-existing.terraform.tfstate
├── uat-new.terraform.tfstate
├── prod-existing.terraform.tfstate
├── prod-new.terraform.tfstate
├── dr-existing.terraform.tfstate
└── dr-new.terraform.tfstate
```

## 📁 Folder Structure


```
terraform/
├── backend-setup/           
│   └── main.tf
├── dev/
│   ├── existing-infra/  
│   │   ├── main.tf
│   │   └── backend.tf     
│   └── new-resources/
│       ├── main.tf
│       └── backend.tf
├── qa/
│   ├── existing-infra/
│   └── new-resources/
├── uat/
│   ├── existing-infra/
│   └── new-resources/
├── prod/
│   ├── existing-infra/
│   └── new-resources/
└── dr/
    ├── existing-infra/
    └── new-resources/
```


## 👥 Authentication

### Single Service Principal

```bash
# Create one service principal for ALL subscriptions
az ad sp create-for-rbac --name "terraform-cloud-team" \
  --role Contributor \
  --scopes \
    /subscriptions/dev-subscription-id \
```

# Terraform Import Demo Guide

## 🎯 Understanding Infrastructure as Code (IaC) Migration

### 🤔 What We're Solving?
**Current Situation:** Your cloud infrastructure was created manually through Azure Portal or scripts. This leads to:
- No version control for infrastructure changes
- Difficult to track who made what changes
- Hard to replicate environments
- No documentation of current state

**Solution:** Bring existing infrastructure under Terraform control using **"brownfield migration"** - importing already created resources into Terraform management.

---

## 🎯 Demo: How to Import Existing Infrastructure

### 📝 Step 1: Create Sample Infrastructure Manually
**Why?** We need existing infrastructure to demonstrate the import process.

```bash
# Create a resource group using Azure CLI
az group create -n dev-rg -l centralindia
```

**💡 What happens here?**
- We're manually creating a resource group in Azure
- This simulates your existing infrastructure that was created manually
- This resource is currently **NOT managed by Terraform**

---

### ⚙️ Step 2: Set Up Terraform Configuration

#### Create `provider.tf` - The Connection Bridge
```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

**🔍 Understanding Providers:**
- **Terraform Providers** are plugins that enable Terraform to interact with cloud platforms
- **AzureRM Provider** lets Terraform talk to Azure
- Think of it as installing the "Azure driver" for Terraform

#### Create `variables.tf` - Configuration Parameters
```hcl
variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
  default     = "dev-rg"
}

variable "resource_group_location" {
  description = "Resource Group location"
  type        = string
  default     = "centralindia"
}
```

**🎯 Why Use Variables?**
- **Avoid hardcoding** - makes code reusable across environments
- **Security** - sensitive data can be passed securely
- **Flexibility** - easy to change values without touching main code

#### Create `main.tf` - Resource Definitions
```hcl
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location
}
```

**📖 Reading This Code:**
- `resource "azurerm_resource_group" "main"` = "I want to manage an Azure Resource Group, and I'll call it 'main' in my code"
- `name = var.resource_group_name` = "The actual Azure name comes from my variable"
- This is like writing a **recipe** for what you want to manage

---

### 💾 Step 3: Configure Remote State Storage

#### Create `backend.tf` - Where Terraform Remembers State
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate11775488"
    container_name       = "tfstate"
    key                  = "dev-existing-infra.terraform.tfstate"
  }
}
```

**🧠 Understanding Terraform State:**
- **Terraform State** is like Terraform's "memory" - it remembers what resources it manages
- **Local State** = Stored on your laptop (risky - if laptop is lost, Terraform forgets everything)
- **Remote State** = Stored in cloud storage (safe, shareable with team)
- **State File Contains:** Resource mappings, attributes, dependencies

**📊 State File Location Breakdown:**
```
Storage Account: tfstate11775488 (secure storage)
└── Container: tfstate (folder for state files)
    └── Key: dev-existing-infra.terraform.tfstate (your project's memory file)
```

---

### 🔄 Step 4: Import Existing Infrastructure

#### Initialize Terraform - Setup Phase
```bash
terraform init
```
**What happens:**
- Downloads Azure provider plugin
- Configures remote backend
- Prepares Terraform to work with your Azure subscription

#### The Magic Import Command
```bash
terraform import azurerm_resource_group.main /subscriptions/xxx/resourceGroups/dev-rg
```

**🎯 Understanding the Import Process:**
```
terraform import [TERRAFORM_RESOURCE_NAME] [AZURE_RESOURCE_ID]
```

**Before Import:**
```
Azure Cloud: [dev-rg resource group] ← Manually created
Terraform:   [main resource definition] ← Just a recipe, not connected
```

**After Import:**
```
Azure Cloud: [dev-rg resource group] 
Terraform:   [main resource definition] ← NOW CONNECTED!
State File:  "I know that 'main' in my code = 'dev-rg' in Azure"
```

---

### ✅ Step 5: Verify Import Success

#### Check If Everything Matches
```bash
terraform plan
```

**🔍 What `terraform plan` Does:**
1. **Reads your code** - what you WANT the infrastructure to be
2. **Checks Azure** - what the infrastructure ACTUALLY is  
3. **Compares** - shows differences between code and reality

**✅ Successful Import Result:**
```
No changes. Your infrastructure matches the configuration.
```

**🎉 This Means:**
- Your code accurately describes the real infrastructure
- Terraform now "owns" this resource
- Any future changes MUST go through Terraform

---

## 🏆 Terraform Best Practices for Real Projects

### 🤔 The Challenge: Multiple Resource Groups
In real projects, you don't have just one resource group. You might have:
- `dev-rg` for development resources
- `cms-rg` for content management system  
- `api-rg` for API services
- `db-rg` for databases
- `network-rg` for networking components

### ❌ The Wrong Way: Repetitive Code
```hcl
# This becomes unmaintainable with 10+ resource groups
resource "azurerm_resource_group" "dev_rg" {
  name     = "dev-rg"
  location = "centralindia"
}

resource "azurerm_resource_group" "cms_rg" {
  name     = "cms-rg"
  location = "southindia" 
}

resource "azurerm_resource_group" "api_rg" {
  name     = "api-rg"
  location = "eastus"
}
# ... and so on for every resource group
```

**Problems with this approach:**
- **Code duplication** - same structure repeated
- **Hard to maintain** - adding new RGs requires code changes
- **Error-prone** - more code = more potential mistakes

### ✅ The Right Way: Using Terraform Loops

#### Smart `main.tf`:
```hcl
resource "azurerm_resource_group" "rgs" {
  for_each = var.resource_groups

  name     = each.key      # The key from our map = resource group name
  location = each.value.location  # The location from our map
  tags     = each.value.tags      # The tags from our map
}
```

#### Smart `variables.tf`:
```hcl
variable "resource_groups" {
  description = "Map of resource groups to manage"
  type = map(object({
    location = string
    tags     = map(string)
  }))
  default = {
    dev-rg = {
      location = "centralindia"
      tags     = {}
    }
    cms-rg = {
      location = "southindia"
      tags = {
        "env" = "dev"
      }
    }
    api-rg = {
      location = "eastus" 
      tags = {
        "project" = "api-services"
      }
    }
  }
}
```

### 🎯 How This Works: The Magic of `for_each`

**Traditional Thinking:** "I need to write code for each resource"

**Terraform Thinking:** "I define a pattern, and Terraform repeats it"

```
Terraform sees your variable map:
{
  "dev-rg": {location: "centralindia", tags: {}},
  "cms-rg": {location: "southindia", tags: {env: "dev"}}
}

Terraform loops through EACH item and creates:
- azurerm_resource_group.rgs["dev-rg"]
- azurerm_resource_group.rgs["cms-rg"] 
```

### 🚀 Adding New Resource Groups is Now Simple

**Before (Traditional):** Add new code block in `main.tf`

**Now (Smart Way):** Just add new entry in `variables.tf`:

```hcl
default = {
  dev-rg = { ... },
  cms-rg = { ... },
  api-rg = { ... },
  # Just add new line here - no code changes needed!
  monitoring-rg = {
    location = "westus"
    tags = { purpose = "monitoring" }
  }
}
```

### 📊 Importing Multiple Resources

```bash
# Clean, consistent import commands
terraform import 'azurerm_resource_group.rgs["dev-rg"]' /subscriptions/xxx/resourceGroups/dev-rg
terraform import 'azurerm_resource_group.rgs["cms-rg"]' /subscriptions/xxx/resourceGroups/cms-rg
terraform import 'azurerm_resource_group.rgs["api-rg"]' /subscriptions/xxx/resourceGroups/api-rg
```
