variable "service_principal_name" {
  type        = string
  description = "The display name for the service principals."
}

variable "project_directory_path" {
  type        = string
  description = "Path/Name of Azure Databricks workspace directory to be created for the project. NOTE: The parent directories in the path must already be created."
}

variable "azure_tenant_id" {
  type        = string
  description = "The Azure tenant ID of the AAD subscription. Must match the one used for the AzureAD Provider."
}
