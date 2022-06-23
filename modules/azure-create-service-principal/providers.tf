terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">= 0.5.8"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.15.0"
    }
  }
}
