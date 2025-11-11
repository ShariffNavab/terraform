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
  
  # Service Principal credentials from environment variables
  # Make sure these are set before running:
  # export ARM_CLIENT_ID="your-sp-client-id"
  # export ARM_CLIENT_SECRET="your-sp-client-secret" 
  # export ARM_SUBSCRIPTION_ID="your-subscription-id"
  # export ARM_TENANT_ID="your-tenant-id"
}

resource "azurerm_resource_group" "tfstate" {
  name     = "tfstate-rg"
  location = "centralindia"
  tags = {
    purpose    = "terraform-backend"
    managed-by = "terraform"
  }
}


# Storage Account for all Terraform states
resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${substr(md5(azurerm_resource_group.tfstate.name), 0, 8)}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  blob_properties {
    versioning_enabled = true
  }

  tags = {
    purpose    = "terraform-backend"
    managed-by = "terraform"
  }
}


resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
#   storage_account_id  = azurerm_storage_account.tfstate.id
  storage_account_name =  azurerm_storage_account.tfstate.name
  container_access_type = "private"
}