# Bloco terraform para definir os provedores necessários
# Terraform block to define required providers
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # version = "=21.90.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "=1.15.0"
    }
  }
}

# Provedor Azure
# Azure provider
provider "azurerm" {
  features {}
}

# Obtém a configuração atual do cliente Azure
# Get the current Azure client configuration
data "azurerm_client_config" "current" {
}


# Obtém informações do workspace Databricks
# Get Databricks workspace information
data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_name
  resource_group_name = local.resource_group
}

# Variáveis locais
# Local variables
locals {
  databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url
}

# Provedor para workspace Databricks
# Provider for Databricks workspace
provider "databricks" {
  host = local.databricks_workspace_host
}

# Provedor para conta Databricks
# Provider for Databricks account
provider "databricks" {
  alias               = "azure_account"
  host                = "https://accounts.azuredatabricks.net"
  account_id          = var.account_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
  auth_type           = "azure-client-secret"
}

# Obtém o principal de serviço do Databricks
# Get Databricks service principal
data "databricks_service_principal" "sp" {
  application_id = var.azure_client_id
}

# Atribui a função de administrador da conta ao principal de serviço
# Assign account admin role to service principal
resource "databricks_service_principal_role" "account_admin" {
  provider             = databricks.azure_account
  service_principal_id = data.azurerm_client_config.current.object_id
  role                 = "account_admin"
}

data "databricks_group" "admins" {
  display_name = "admins"
}

resource "databricks_user" "me" {
  user_name = var.user_principal_name
}

resource "databricks_group_member" "i-am-admin" {
  group_id  = data.databricks_group.admins.id
  member_id = databricks_user.me.id
}

# Módulo que cria o metastore UC e adiciona usuários, grupos e principais de serviço à conta Azure Databricks
# Module creating UC metastore and adding users, groups and service principals to Azure Databricks account
module "metastore_and_users" {
  source              = "./modules/adb-metastore-and-users"
  databricks_name     = local.databricks_name
  resource_group      = local.resource_group
  aad_groups          = var.aad_groups
  account_id          = var.account_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
  prefix              = local.suffix_concat
  container_metastore = local.container_metastore
  storage_account     = local.storage_account
}

# Variáveis locais para usuários e principais de serviço
# Local variables for users and service principals
locals {
  merged_user_sp = merge(module.metastore_and_users.databricks_users, module.metastore_and_users.databricks_sps)
  aad_groups     = toset(var.aad_groups)
}

# Lê os membros dos grupos do AzureAD toda vez que o Terraform é iniciado
# Read group members of given groups from AzureAD every time Terraform is started
data "azuread_group" "this" {
  for_each     = local.aad_groups
  display_name = each.value
}

# Adiciona usuários e principais de serviço aos seus respectivos grupos
# Add users and service principals to their respective groups
resource "databricks_group_member" "this" {
  provider = databricks.azure_account
  for_each = toset(flatten([
    for group, details in data.azuread_group.this : [
      for member in details["members"] : jsonencode({
        group  = module.metastore_and_users.databricks_groups[details["object_id"]],
        member = local.merged_user_sp[member]
      })
    ]
  ]))
  group_id   = jsondecode(each.value).group
  member_id  = jsondecode(each.value).member
  depends_on = [module.metastore_and_users]
}

# Federação de identidade - adicionando usuários/grupos da conta Databricks ao workspace
# Identity federation - adding users/groups from Databricks account to workspace
resource "databricks_mws_permission_assignment" "workspace_user_groups" {
  for_each     = data.azuread_group.this
  provider     = databricks.azure_account
  workspace_id = module.metastore_and_users.databricks_workspace_id
  principal_id = module.metastore_and_users.databricks_groups[each.value["object_id"]]
  permissions  = each.key == "account_unity_admin" ? ["ADMIN"] : ["USER"]
  depends_on   = [databricks_group_member.this]
}

# Cria um contêiner na conta de armazenamento para ser usado pelo catálogo de desenvolvimento como armazenamento raiz
# Create a container in the storage account to be used by dev catalog as root storage
resource "azurerm_storage_container" "dev_catalog" {
  name                  = local.container_catalog
  storage_account_name  = module.metastore_and_users.azurerm_storage_account_unity_catalog.name
  container_access_type = "private"
}

# Cria credenciais de armazenamento para criar uma localização externa
# Create storage credentials to create an external location
resource "databricks_storage_credential" "external_mi" {
  name = "external_location_mi_credential"
  azure_managed_identity {
    access_connector_id = module.metastore_and_users.azurerm_databricks_access_connector_id
  }
  comment    = "Storage credential for all external locations"
  depends_on = [databricks_mws_permission_assignment.workspace_user_groups]
}

# Cria uma localização externa para ser usada como armazenamento raiz pelo catálogo de desenvolvimento
# Create an external location to be used as root storage by dev catalog
resource "databricks_external_location" "dev_location" {
  name = "dtmaster-catalog-external-location"
  url = format("abfss://%s@%s.dfs.core.windows.net/",
    local.container_catalog,
  module.metastore_and_users.azurerm_storage_account_unity_catalog.name)
  credential_name = databricks_storage_credential.external_mi.id
  comment         = "External location used by dev catalog as root storage"
  depends_on      = [databricks_storage_credential.external_mi]
}

# Cria uma localização externa para ser usada como armazenamento raiz pelo catálogo de desenvolvimento
# Create an external location to be used as root storage by dev catalog
resource "databricks_external_location" "raw_location" {
  name = "raw-catalog-external-location"
  url = format("abfss://%s@%s.dfs.core.windows.net/",
    local.container_raw,
  module.metastore_and_users.azurerm_storage_account_unity_catalog.name)
  credential_name = databricks_storage_credential.external_mi.id
  comment         = "External location used by dev catalog as root storage"
  depends_on      = [databricks_storage_credential.external_mi]
}

resource "databricks_grants" "ext_loc_raw" {
  external_location = databricks_external_location.raw_location.id
  grant {
    principal  = "data_engineer"
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES"]
  }
}

# Cria o catálogo de desenvolvimento
# Create dev environment catalog
resource "databricks_catalog" "dev" {
  metastore_id = module.metastore_and_users.metastore_id
  name         = local.catalog_name
  comment      = "this catalog is for dtmaster env"
  storage_root = databricks_external_location.dev_location.url
  properties = {
    purpose = "dtmaster"
  }
  depends_on = [module.metastore_and_users, databricks_external_location.dev_location]
}

# Concede permissões no catálogo de desenvolvimento
# Grants on dev catalog
resource "databricks_grants" "dev_catalog" {
  catalog = databricks_catalog.dev.name
  grant {
    principal  = "data_engineer"
    privileges = ["USE_CATALOG"]
  }
  depends_on = [databricks_catalog.dev]
}

# Cria o esquema para a camada bronze do datalake no ambiente de desenvolvimento
# Create schema for bronze datalake layer in dev env.
resource "databricks_schema" "bronze" {
  catalog_name = databricks_catalog.dev.id
  name         = "bronze"
  owner        = "data_engineer"
  comment      = "this database is for bronze layer tables/views"
  depends_on   = [databricks_catalog.dev]
}

# Concede permissões no esquema bronze
# Grants on bronze schema
resource "databricks_grants" "bronze" {
  schema = databricks_schema.bronze.id
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }
  depends_on = [databricks_catalog.dev]
}

# Cria o esquema para a camada silver do datalake no ambiente de desenvolvimento
# Create schema for silver datalake layer in dev env.
resource "databricks_schema" "silver" {
  catalog_name = databricks_catalog.dev.id
  name         = "silver"
  owner        = "data_engineer"
  comment      = "this database is for silver layer tables/views"
  depends_on   = [databricks_catalog.dev]
}

# Concede permissões no esquema silver
# Grants on silver schema
resource "databricks_grants" "silver" {
  schema = databricks_schema.silver.id
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }
  depends_on = [databricks_catalog.dev]
}

# Cria o esquema para a camada gold do datalake no ambiente de desenvolvimento
# Create schema for gold datalake layer in dev env.
resource "databricks_schema" "gold" {
  catalog_name = databricks_catalog.dev.id
  name         = "gold"
  owner        = "data_engineer"
  comment      = "this database is for gold layer tables/views"
  depends_on   = [databricks_catalog.dev]
}

# Concede permissões no esquema gold
# Grants on gold schema
resource "databricks_grants" "gold" {
  schema = databricks_schema.gold.id
  grant {
    principal  = "data_engineer"
    privileges = ["USE_SCHEMA", "CREATE_FUNCTION", "CREATE_TABLE", "EXECUTE", "MODIFY", "SELECT"]
  }
  depends_on = [databricks_catalog.dev]
}
