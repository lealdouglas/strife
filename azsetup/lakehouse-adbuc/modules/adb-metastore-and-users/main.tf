# Bloco terraform para definir os provedores necessários
# Terraform block to define required providers
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
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

# Obtém o grupo de recursos do Azure
# Get the Azure resource group
data "azurerm_resource_group" "this" {
  name = var.resource_group
}

# Obtém informações do workspace Databricks
# Get Databricks workspace information
data "azurerm_databricks_workspace" "this" {
  name                = var.databricks_name
  resource_group_name = var.resource_group
}

# Provedor para workspace Databricks
# Provider for Databricks workspace
provider "databricks" {
  host = local.databricks_workspace_host
}

# Inicializa o provedor no nível da conta Azure
# Initialize provider at Azure account-level
provider "databricks" {
  alias               = "azure_account"
  host                = "https://accounts.azuredatabricks.net"
  account_id          = var.account_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
  auth_type           = "azure-client-secret"
}

# Cria uma identidade gerenciada do Azure para ser usada pelo metastore do Unity Catalog
# Create an Azure managed identity to be used by Unity Catalog metastore
data "azurerm_databricks_access_connector" "unity" {
  name                = "${var.databricks_name}-mi"
  resource_group_name = data.azurerm_resource_group.this.name
}

# Cria uma conta de armazenamento gen2 no grupo de recursos
# Create a storage account gen2 in the resource group
data "azurerm_storage_account" "unity_catalog" {
  resource_group_name = data.azurerm_resource_group.this.name
  name                = var.storage_account
}

# Cria um contêiner na conta de armazenamento para ser usado pelo metastore do Unity Catalog
# Create a container in the storage account to be used by Unity Catalog metastore
data "azurerm_storage_container" "unity_catalog" {
  storage_account_name = data.azurerm_storage_account.unity_catalog.name
  name                 = var.container_metastore
}

# Cria o primeiro metastore do Unity Catalog
# Create the first Unity Catalog metastore
resource "databricks_metastore" "this" {
  name = "primary"
  storage_root = format("abfss://%s@%s.dfs.core.windows.net/",
    data.azurerm_storage_container.unity_catalog.name,
  data.azurerm_storage_account.unity_catalog.name)
  force_destroy = true
}

# Atribui a identidade gerenciada ao metastore
# Assign managed identity to metastore
resource "databricks_metastore_data_access" "first" {
  metastore_id = databricks_metastore.this.id
  name         = "the-metastore-key"
  azure_managed_identity {
    access_connector_id = data.azurerm_databricks_access_connector.unity.id
  }
  is_default = true
}

# Anexa o workspace Databricks ao metastore
# Attach the Databricks workspace to the metastore
resource "databricks_metastore_assignment" "this" {
  workspace_id         = local.databricks_workspace_id
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

# Variáveis locais para grupos AAD
# Local variables for AAD groups
locals {
  aad_groups = toset(var.aad_groups)
}

# Lê os membros dos grupos do AzureAD toda vez que o Terraform é iniciado
# Read group members of given groups from AzureAD every time Terraform is started
data "azuread_group" "this" {
  for_each     = local.aad_groups
  display_name = each.value
}

# Adiciona grupos à conta Databricks
# Add groups to Databricks account
resource "databricks_group" "this" {
  provider     = databricks.azure_account
  for_each     = data.azuread_group.this
  display_name = each.key
  external_id  = data.azuread_group.this[each.key].object_id
  force        = true
}

# Variáveis locais para todos os membros
# Local variables for all members
locals {
  all_members = toset(flatten([for group in values(data.azuread_group.this) : group.members]))
}

# Extrai informações sobre usuários reais
# Extract information about real users
data "azuread_users" "users" {
  ignore_missing = true
  object_ids     = local.all_members
}

# Variáveis locais para todos os usuários
# Local variables for all users
locals {
  all_users = {
    for user in data.azuread_users.users.users : user.object_id => user
  }
}

# Todos governados pelo AzureAD, cria ou remove usuários da conta Databricks
# All governed by AzureAD, create or remove users from Databricks account
resource "databricks_user" "this" {
  provider     = databricks.azure_account
  for_each     = local.all_users
  user_name    = lower(local.all_users[each.key]["user_principal_name"])
  display_name = local.all_users[each.key]["display_name"]
  active       = local.all_users[each.key]["account_enabled"]
  external_id  = each.key
  force        = true

  # Revisar aviso antes de desativar ou excluir usuários da conta Databricks
  # Review warning before deactivating or deleting users from Databricks account
  lifecycle {
    prevent_destroy = true
  }
}

# Extrai informações sobre principais de serviço
# Extract information about service principals
data "azuread_service_principals" "spns" {
  object_ids = toset(setsubtract(local.all_members, data.azuread_users.users.object_ids))
}

# Variáveis locais para todos os principais de serviço
# Local variables for all service principals
locals {
  all_spns = {
    for sp in data.azuread_service_principals.spns.service_principals : sp.object_id => sp
  }
}

# Todos governados pelo AzureAD, cria ou remove principais de serviço da conta Databricks
# All governed by AzureAD, create or remove service principals from Databricks account
resource "databricks_service_principal" "sp" {
  provider       = databricks.azure_account
  for_each       = local.all_spns
  application_id = local.all_spns[each.key]["application_id"]
  display_name   = local.all_spns[each.key]["display_name"]
  active         = local.all_spns[each.key]["account_enabled"]
  external_id    = each.key
  force          = false
}

# Variáveis locais para membros administradores da conta
# Local variables for account admin members
locals {
  account_admin_members = toset(flatten([for group in values(data.azuread_group.this) : [group.display_name == "account_unity_admin" ? group.members : []]]))
}

# Extrai informações sobre usuários administradores da conta
# Extract information about account admin users
data "azuread_users" "account_admin_users" {
  ignore_missing = true
  object_ids     = local.account_admin_members
}

# Variáveis locais para todos os usuários administradores da conta
# Local variables for all account admin users
locals {
  all_account_admin_users = {
    for user in data.azuread_users.account_admin_users.users : user.object_id => user
  }
}

# Tornando todos os usuários do grupo account_unity_admin como administradores da conta Databricks
# Making all users in account_unity_admin group as Databricks account admins
resource "databricks_user_role" "account_admin" {
  provider   = databricks.azure_account
  for_each   = local.all_account_admin_users
  user_id    = databricks_user.this[each.key].id
  role       = "account_admin"
  depends_on = [databricks_group.this, databricks_user.this, databricks_service_principal.sp]
}
