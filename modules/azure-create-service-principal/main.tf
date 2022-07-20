variable "display_name" {
  type        = string
  description = "The display name for the service principal in Databricks."
}

variable "group_name" {
  type        = string
  description = "The Databricks group name that the service principal will belong to. NOTE: The main purpose of this group is to give the service principal token usage permissions, so the group should have token usage permissions."
}

variable "azure_tenant_id" {
  type        = string
  description = "The Azure tenant ID of the AAD subscription. Must match the one used for the AzureAD Provider."
}

data "azuread_client_config" "current" {}

resource "azuread_application" "service_principal" {
  display_name = var.display_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_password" "client_secret" {
  application_object_id = azuread_application.service_principal.object_id
}

resource "databricks_service_principal" "sp" {
  application_id       = azuread_application.service_principal.application_id
  display_name         = var.display_name
  allow_cluster_create = true
}

data "databricks_group" "sp_group" {
  display_name = var.group_name
}

resource "databricks_group_member" "add_sp_to_group" {
  group_id  = data.databricks_group.sp_group.id
  member_id = databricks_service_principal.sp.id
}

data "external" "token" {
  program = ["python", "${path.module}/get-aad-token.py"]
  query = {
    client_id     = azuread_application.service_principal.application_id
    client_secret = azuread_application_password.client_secret.value
    tenant_id     = var.azure_tenant_id
  }
  depends_on = [databricks_group_member.add_sp_to_group]
}

output "service_principal_application_id" {
  value       = databricks_service_principal.sp.application_id
  description = "Application ID of the created Azure Databricks service principal. Identical to the Azure client ID of the created AAD application associated with the service principal."
}

output "service_principal_aad_token" {
  value       = data.external.token.result.token
  sensitive   = true
  description = "Sensitive AAD token value of the created Azure Databricks service principal."
}

output "service_principal_client_secret" {
  value       = azuread_application_password.client_secret.value
  sensitive   = true
  description = "Sensitive AAD client secret of the created AAD application associated with the service principal. NOTE: Client secret is created with a default lifetime of 2 years."
}
