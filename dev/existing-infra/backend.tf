terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate11775488"
    container_name       = "tfstate"
    key                  = "dev-existing-infra.terraform.tfstate"
  }
}