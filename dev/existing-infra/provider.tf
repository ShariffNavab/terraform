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