terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-dev"
    storage_account_name = "ameytfstate57317074"
    container_name       = "tfstate"
    key                  = "dev.network.tfstate"
    use_azuread_auth     = true
  }
}
