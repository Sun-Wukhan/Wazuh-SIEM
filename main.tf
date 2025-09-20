terraform {
  cloud {
    organization = "Insert-Org-Here"

    workspaces {
      name = "SIEM"
    }
  }
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

resource "azurerm_resource_group" "this" {
  name     = "siem-prod"
  location = "canada central"
}
