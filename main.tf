data "databricks_group" "staging_sp_group" {
  provider     = databricks.staging
  display_name = var.service_principal_group_name
}

data "databricks_group" "prod_sp_group" {
  provider     = databricks.prod
  display_name = var.service_principal_group_name
}

module "create_staging_sp" {
  source = "./modules/azure-create-service-principal"
  providers = {
    databricks = databricks.staging
    azuread    = azuread
  }
  display_name    = "READ-only Model Registry Service Principal"
  group_name      = data.databricks_group.staging_sp_group.display_name
  azure_tenant_id = var.azure_tenant_id
}

module "create_prod_sp" {
  source = "./modules/azure-create-service-principal"
  providers = {
    databricks = databricks.prod
    azuread    = azuread
  }
  display_name    = "READ-only Model Registry Service Principal"
  group_name      = data.databricks_group.prod_sp_group.display_name
  azure_tenant_id = var.azure_tenant_id
}

resource "databricks_directory" "staging_directory" {
  provider = databricks.staging
  path     = var.project_directory_path
}

resource "databricks_permissions" "staging_directory_usage" {
  provider       = databricks.staging
  directory_path = databricks_directory.staging_directory.path

  access_control {
    service_principal_name = module.create_staging_sp.service_principal_application_id
    permission_level       = "CAN_MANAGE"
  }
}

resource "databricks_directory" "prod_directory" {
  provider = databricks.prod
  path     = var.project_directory_path
}

resource "databricks_permissions" "prod_directory_usage" {
  provider       = databricks.prod
  directory_path = databricks_directory.prod_directory.path

  access_control {
    service_principal_name = module.create_prod_sp.service_principal_application_id
    permission_level       = "CAN_MANAGE"
  }
}
