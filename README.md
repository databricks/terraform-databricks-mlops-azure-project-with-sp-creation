# MLOps Azure Project Module with Service Principal Creation

In both of the specified staging and prod workspaces, this module:
* Creates an AAD application and associates it with a newly created Azure Databricks service principal, configuring appropriate permissions and entitlements to run CI/CD for a project. 
* Creates a workspace directory as a container for project-specific resources

The service principals are granted `CAN_MANAGE` permissions on the created workspace directories.

**_NOTE:_** 
1. This module is in preview so it is still experimental and subject to change. Feedback is welcome!
2. The [Databricks providers](https://registry.terraform.io/providers/databricks/databricks/latest/docs) that are passed into the module must be configured with workspace admin permissions.
3. The [Azure Active Directory (AzureAD) provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs) that is passed into the module must be configured with [Application.ReadWrite.All](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password#api-permissions) permissions to allow AAD application creation to link to an Azure Databricks service principal. This provider can be authenticated via an AAD [service principal](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/service-principals#create-a-service-principal) with the Application.ReadWrite.All permission.
4. The module assumes that one of the two Azure Infrastructure Modules (with [Creation](https://registry.terraform.io/modules/databricks/mlops-azure-infrastructure-with-sp-creation/databricks/latest) or [Linking](https://registry.terraform.io/modules/databricks/mlops-azure-infrastructure-with-sp-linking/databricks/latest)) has already been applied, namely that service principal groups with token usage permissions have been created with the default name `"mlops-service-principals"` or by specifying the `service_principal_group_name` field.
5. The service principal AAD tokens are short-lived (<60 minutes in most cases). If a long-lived token is desired, the AAD token can be used to authenticate into a Databricks provider and provision a personal access token (PAT) for the service principal.

## Usage
```hcl
provider "databricks" {
  alias = "staging"     # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "prod"     # Authenticate using preferred method as described in Databricks provider
}

provider "azuread" {} # Authenticate using preferred method as described in AzureAD provider

module "mlops_azure_project_with_sp_creation" {
  source = "databricks/mlops-azure-project-with-sp-creation/databricks"
  providers = {
    databricks.staging = databricks.staging
    databricks.prod = databricks.prod
    azuread = azuread
  }
  service_principal_name = "example-name"
  project_directory_path = "/dir-name"
  azure_tenant_id        = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
}
```

### Usage example with Git credentials for service principal
This can be helpful for common use cases such as Git authorization for [Remote Git Jobs](https://docs.databricks.com/repos/jobs-remote-notebook.html).
```hcl
data "databricks_current_user" "staging_user" {
  provider = databricks.staging
}

data "databricks_current_user" "prod_user" {
  provider = databricks.prod
}

provider "databricks" {
  alias = "staging_sp"
  host  = data.databricks_current_user.staging_user.workspace_url
  token = module.mlops_azure_project_with_sp_creation.staging_service_principal_aad_token
}

provider "databricks" {
  alias = "prod_sp"
  host  = data.databricks_current_user.prod_user.workspace_url
  token = module.mlops_azure_project_with_sp_creation.prod_service_principal_aad_token
}

resource "databricks_git_credential" "staging_git" {
  provider              = databricks.staging_sp
  git_username          = var.git_username
  git_provider          = var.git_provider
  personal_access_token = var.git_token    # This should be configured with `repo` scope for Databricks Repos.
}

resource "databricks_git_credential" "prod_git" {
  provider              = databricks.prod_sp
  git_username          = var.git_username
  git_provider          = var.git_provider
  personal_access_token = var.git_token    # This should be configured with `repo` scope for Databricks Repos.
}
```

### Usage example with [MLOps Azure Infrastructure Module with Service Principal Creation](https://registry.terraform.io/modules/databricks/mlops-azure-infrastructure-with-sp-creation/databricks/latest)
```hcl
provider "databricks" {
  alias = "dev" # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "staging"     # Authenticate using preferred method as described in Databricks provider
}

provider "databricks" {
  alias = "prod"     # Authenticate using preferred method as described in Databricks provider
}

provider "azuread" {} # Authenticate using preferred method as described in AzureAD provider

module "mlops_azure_infrastructure_with_sp_creation" {
  source = "databricks/mlops-azure-infrastructure-with-sp-creation/databricks"
  providers = {
    databricks.dev = databricks.dev
    databricks.staging = databricks.staging
    databricks.prod = databricks.prod
    azuread = azuread
  }
  staging_workspace_id          = "123456789"
  prod_workspace_id             = "987654321"
  azure_tenant_id               = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
  additional_token_usage_groups = ["users"]     # This field is optional.
}

module "mlops_azure_project_with_sp_creation" {
  source = "databricks/mlops-azure-project-with-sp-creation/databricks"
  providers = {
    databricks.staging = databricks.staging
    databricks.prod = databricks.prod
    azuread = azuread
  }
  service_principal_name = "example-name"
  project_directory_path = "/dir-name"
  azure_tenant_id        = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
  service_principal_group_name = module.mlops_azure_infrastructure_with_sp_creation.service_principal_group_name 
  # The above field is optional, especially since in this case service_principal_group_name will be mlops-service-principals either way, 
  # but this also serves to create an implicit dependency. Can also be replaced with the following line to create an explicit dependency:
  # depends_on             = [module.mlops_azure_infrastructure_with_sp_creation]
}
```

## Requirements
| Name | Version |
|------|---------|
|[terraform](https://registry.terraform.io/)|\>=1.1.6|
|[databricks](https://registry.terraform.io/providers/databricks/databricks/0.5.8)|\>=0.5.8|
|[azuread](https://registry.terraform.io/providers/hashicorp/azuread/2.15.0)|\>=2.15.0|
|[python](https://www.python.org/downloads/release/python-380/)|\>=3.8|

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
|service_principal_name|The display name for the service principals.|string|N/A|yes|
|project_directory_path|Path/Name of Azure Databricks workspace directory to be created for the project. NOTE: The parent directories in the path must already be created.|string|N/A|yes|
|azure_tenant_id|The [Azure tenant ID](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-how-to-find-tenant) of the AAD subscription. Must match the one used for the AzureAD Provider.|string|N/A|yes|
|service_principal_group_name|The name of the service principal group in the staging and prod workspace. The created service principals will be added to this group.|string|`"mlops-service-principals"`|no|

## Outputs
| Name | Description | Type | Sensitive |
|------|-------------|------|---------|
|project_directory_path|Path/Name of Azure Databricks workspace directory created for the project.|string|no|
|staging_service_principal_application_id|Application ID of the created Azure Databricks service principal in the staging workspace. Identical to the Azure client ID of the created AAD application associated with the service principal.|string|no|
|staging_service_principal_aad_token|Sensitive AAD token value of the created Azure Databricks service principal in the staging workspace.|string|yes|
|staging_service_principal_client_secret|Sensitive AAD client secret of the created AAD application associated with the staging service principal. NOTE: Client secret is created with a default lifetime of 2 years.|string|yes|
|prod_service_principal_application_id|Application ID of the created Azure Databricks service principal in the prod workspace. Identical to the Azure client ID of the created AAD application associated with the service principal.|string|no|
|prod_service_principal_aad_token|Sensitive AAD token value of the created Azure Databricks service principal in the prod workspace.|string|yes|
|prod_service_principal_client_secret|Sensitive AAD client secret of the created AAD application associated with the prod service principal. NOTE: Client secret is created with a default lifetime of 2 years.|string|yes|

## Providers
| Name | Authentication | Use |
|------|-------------|----|
|databricks.staging|Provided by the user.|Create group, directory, and service principal module in the staging workspace.|
|databricks.prod|Provided by the user.|Create group, directory, and service principal module in the prod workspace.|
|azuread|Provided by the user. Can be authenticated via [azure_client_id, azure_client_secret, azure_tenant_id](https://registry.terraform.io/providers/hashicorp/azuread/2.15.0/docs/guides/service_principal_client_secret).| Create an AAD application and client secret for the service principal.|

## Resources
| Name | Type |
|------|------|
|databricks_group.staging_sp_group|data source|
|databricks_group.prod_sp_group|data source|
|databricks_directory.staging_directory|resource|
|databricks_permissions.staging_directory_usage|resource|
|databricks_directory.prod_directory|resource|
|databricks_permissions.prod_directory_usage|resource|
|azure-create-service-principal.create_staging_sp|module|
|azure-create-service-principal.create_prod_sp|module|

## Known Issues
- AAD token generation occasionally fails with `"HTTP Error 400: Bad Request"` but the query is not actually invalid.
    - Solution: Re-run `terraform apply` and the error should disappear.