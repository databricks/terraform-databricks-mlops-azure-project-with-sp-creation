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

provider "databricks" {
  alias = "staging"
}

provider "databricks" {
  alias = "prod"
}

provider "azuread" {}

module "mlops_azure_project_with_sp_creation" {
  source = "../."
  providers = {
    databricks.staging = databricks.staging
    databricks.prod    = databricks.prod
    azuread            = azuread
  }
  service_principal_name = "example-name"
  project_directory_path = "/dir-name"
  azure_tenant_id        = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
}