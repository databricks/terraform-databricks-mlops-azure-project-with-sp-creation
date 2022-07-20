# Azure Create Service Principal Module

This module will create an Azure Active Directory (AAD) Application and link it to a new Azure Databricks Service Principal in a workspace, outputting its application ID and AAD token. The AAD token can be used within the same Terraform configuration e.g. to authenticate to Databricks, but note that it is short-lived and so not fit to be persisted and reused over time.

**_NOTE:_**
1. The [Databricks provider](https://registry.terraform.io/providers/databricks/databricks/latest/docs) that is passed into the module must be configured with workspace admin permissions to allow service principal creation.
2. The [Azure Active Directory (AzureAD) provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs) that is passed into the module must be configured with [Application.ReadWrite.All](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password#api-permissions) permissions to allow AAD application creation to link to an Azure Databricks service principal. This provider can be authenticated via an AAD [service principal](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/service-principals#create-a-service-principal) with the Application.ReadWrite.All permission.
3. This module requires that Python 3.8+ be installed to run `get-aad-token.py` to obtain the service principal's AAD token.

## Usage
```hcl
provider "databricks" {} # Authenticate using preferred method as described in Databricks provider

provider "azuread" {} # Authenticate using preferred method as described in AzureAD provider

module "azure_create_sp" {
  source = "databricks/azure-create-service-principal/databricks"
  providers = {
    databricks = databricks
    azuread = azuread
  }
  display_name    = "example-name"
  group_name      = "example-group"
  azure_tenant_id = "a1b2c3d4-e5f6-g7h8-i9j0-k9l8m7n6o5p4"
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
|display_name|The desired display name for the service principal in Azure Databricks.|string|N/A|yes|
|group_name|The Azure Databricks group name that the service principal will belong to. NOTE: The main purpose of this group is to give the service principal token usage permissions, so the group should have token usage permissions.|string|N/A|yes|
|azure_tenant_id|The [Azure tenant ID](https://docs.microsoft.com/en-us/azure/active-directory/fundamentals/active-directory-how-to-find-tenant) of the AAD subscription. Must match the one used for the AzureAD Provider.|string|N/A|yes|

## Outputs
| Name | Description | Type | Sensitive |
|------|-------------|------|---------|
|service_principal_application_id|Application ID of the created Azure Databricks service principal. Identical to the Azure client ID of the created AAD application associated with the service principal.|string|no|
|service_principal_aad_token|Sensitive AAD token value of the created Azure Databricks service principal. NOTE: This token is short-lived, and if a long-term token is needed, this token can be used for service principal authentication into an Azure Databricks workspace to generate a long-lived personal access token (PAT) for the service principal.|string|yes|
|service_principal_client_secret|Sensitive AAD client secret of the created AAD application associated with the service principal. NOTE: Client secret is created with a default lifetime of 2 years.|string|yes|

## Providers
| Name | Authentication | Use |
|------|-------------|----|
|databricks|Provided by the user.|Generate all Azure Databricks workspace resources.|
|azuread|Provided by the user. Can be authenticated via [azure_client_id, azure_client_secret, azure_tenant_id](https://registry.terraform.io/providers/hashicorp/azuread/2.15.0/docs/guides/service_principal_client_secret)| Create an AAD application and client secret for the service principal.|
|external|N/A|Run Python script that sends a POST request to Azure to obtain the service principal's AAD token.|

## Resources
| Name | Type |
|------|------|
|azuread_client_config.current|data source|
|azuread_application.service_principal|resource|
|azuread_application_password.client_secret|resource|
|databricks_service_principal.sp|resource|
|databricks_group.sp_group|data source|
|databricks_group_member.add_sp_to_group|resource|
|external.token|data source|

## Known Issues
- AAD token generation occasionally fails with `"HTTP Error 400: Bad Request"` but the query is not actually invalid.
    - Solution: Re-run `terraform apply` and the error should disappear.