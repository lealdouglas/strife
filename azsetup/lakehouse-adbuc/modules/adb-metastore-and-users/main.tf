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

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "this" {
  name = var.resource_group
}

data "azurerm_databricks_workspace" "this" {
  name                = var.databricks_workspace_name
  resource_group_name = var.resource_group
}

locals {
  databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url
  databricks_workspace_id   = data.azurerm_databricks_workspace.this.workspace_id
  prefix                    = var.prefix
}

// Provider for databricks workspace
provider "databricks" {
  host = local.databricks_workspace_host
}

// Initialize provider at Azure account-level
# Config: host=https://accounts.azuredatabricks.net, account_id=***, azure_client_secret=***, azure_client_id=000000, azure_tenant_id=000000. Env: ARM_CLIENT_SECRET, ARM_CLIENT_ID, ARM_TENANT_ID
provider "databricks" {
  alias               = "azure_account"
  host                = "https://accounts.azuredatabricks.net"
  account_id          = var.account_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
  auth_type           = "azure-client-secret"
}


// Create azure managed identity to be used by unity catalog metastore
resource "azurerm_databricks_access_connector" "unity" {
  name                = "adb${local.prefix}-mi"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
}

# Create a storage account gen2 in resource group
data "azurerm_storage_account" "unity_catalog" {
  resource_group_name = data.azurerm_resource_group.this.name
  name                = "sta${local.prefix}"
}

# Create a storage account gen2 in resource group
data "azurerm_storage_container" "unity_catalog" {
  storage_account_name = data.azurerm_storage_account.unity_catalog.name
  name                 = "ctr${local.prefix}"
}

// Create the first unity catalog metastore
resource "databricks_metastore" "this" {
  name = "primary"
  storage_root = format("abfss://%s@%s.dfs.core.windows.net/",
    data.azurerm_storage_container.unity_catalog.name,
  data.azurerm_storage_account.unity_catalog.name)
  force_destroy = true
  owner         = "account_unity_admin"
}

// Assign managed identity to metastore
resource "databricks_metastore_data_access" "first" {
  metastore_id = databricks_metastore.this.id
  name         = "the-metastore-key"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity.id
  }
  is_default = true
}

// Attach the databricks workspace to the metastore
resource "databricks_metastore_assignment" "this" {
  workspace_id         = local.databricks_workspace_id
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

locals {
  aad_groups = toset(var.aad_groups)
}

// Read group members of given groups from AzureAD every time Terraform is started
data "azuread_group" "this" {
  for_each     = local.aad_groups
  display_name = each.value
}

// Add groups to databricks account
resource "databricks_group" "this" {
  provider     = databricks.azure_account
  for_each     = data.azuread_group.this
  display_name = each.key
  external_id  = data.azuread_group.this[each.key].object_id
  force        = true
}

locals {
  all_members = toset(flatten([for group in values(data.azuread_group.this) : group.members]))
}

// Extract information about real users
data "azuread_users" "users" {
  ignore_missing = true
  object_ids     = local.all_members
}

locals {
  all_users = {
    for user in data.azuread_users.users.users : user.object_id => user
  }
}

// All governed by AzureAD, create or remove users to/from databricks account
resource "databricks_user" "this" {
  provider     = databricks.azure_account
  for_each     = local.all_users
  user_name    = lower(local.all_users[each.key]["user_principal_name"])
  display_name = local.all_users[each.key]["display_name"]
  active       = local.all_users[each.key]["account_enabled"]
  external_id  = each.key
  force        = true

  // Review warning before deactivating or deleting users from databricks account
  // https://learn.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/scim/#add-users-and-groups-to-your-azure-databricks-account-using-azure-active-directory-azure-ad
  lifecycle {
    prevent_destroy = true
  }
}

// Extract information about service prinicpals users
data "azuread_service_principals" "spns" {
  object_ids = toset(setsubtract(local.all_members, data.azuread_users.users.object_ids))
}

locals {
  all_spns = {
    for sp in data.azuread_service_principals.spns.service_principals : sp.object_id => sp
  }
}

// All governed by AzureAD, create or remove service to/from databricks account
resource "databricks_service_principal" "sp" {
  provider       = databricks.azure_account
  for_each       = local.all_spns
  application_id = local.all_spns[each.key]["application_id"]
  display_name   = local.all_spns[each.key]["display_name"]
  active         = local.all_spns[each.key]["account_enabled"]
  external_id    = each.key
  force          = true
}

locals {
  account_admin_members = toset(flatten([for group in values(data.azuread_group.this) : [group.display_name == "account_unity_admin" ? group.members : []]]))
}
# Extract information about real account admins users
data "azuread_users" "account_admin_users" {
  ignore_missing = true
  object_ids     = local.account_admin_members
}

locals {
  all_account_admin_users = {
    for user in data.azuread_users.account_admin_users.users : user.object_id => user
  }
}

// Making all users on account_unity_admin group as databricks account admin
resource "databricks_user_role" "account_admin" {
  provider   = databricks.azure_account
  for_each   = local.all_account_admin_users
  user_id    = databricks_user.this[each.key].id
  role       = "account_admin"
  depends_on = [databricks_group.this, databricks_user.this, databricks_service_principal.sp]
}

# terraform {
#   required_providers {
#     azurerm = {
#       source = "hashicorp/azurerm"
#       # version = "=21.90.0"
#     }
#     databricks = {
#       source  = "databricks/databricks"
#       version = "=1.15.0"
#     }
#   }
# }

# provider "azurerm" {
#   features {}
# }

# data "azurerm_resource_group" "this" {
#   name = var.resource_group
# }

# data "azurerm_databricks_workspace" "this" {
#   name                = var.databricks_workspace_name
#   resource_group_name = var.resource_group
# }

# locals {
#   databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url
#   databricks_workspace_id   = data.azurerm_databricks_workspace.this.workspace_id
#   prefix                    = var.prefix
# }

# // Provider for databricks workspace
# provider "databricks" {
#   host = local.databricks_workspace_host
# }

# // Initialize provider at Azure account-level
# # Config: host=https://accounts.azuredatabricks.net, account_id=***, azure_client_secret=***, azure_client_id=000000, azure_tenant_id=000000. Env: ARM_CLIENT_SECRET, ARM_CLIENT_ID, ARM_TENANT_ID
# provider "databricks" {
#   alias               = "azure_account"
#   host                = "https://accounts.azuredatabricks.net"
#   account_id          = var.account_id
#   azure_client_id     = var.azure_client_id
#   azure_client_secret = var.azure_client_secret
#   azure_tenant_id     = var.azure_tenant_id
#   auth_type           = "azure-client-secret"
# }

# # resource "databricks_service_principal_role" "my_service_principal_instance_profile" {
# #   service_principal_id = var.azure_client_id
# #   role                 = "account_admin"
# # }

# // Create azure managed identity to be used by unity catalog metastore
# resource "azurerm_databricks_access_connector" "unity" {
#   name                = "adb${local.prefix}-mi"
#   resource_group_name = data.azurerm_resource_group.this.name
#   location            = data.azurerm_resource_group.this.location
# }

# # Create a storage account gen2 in resource group
# data "azurerm_storage_account" "unity_catalog" {
#   resource_group_name = data.azurerm_resource_group.this.name
#   name                = "sta${local.prefix}"
# }

# # Create a storage account gen2 in resource group
# data "azurerm_storage_container" "unity_catalog" {
#   storage_account_name = data.azurerm_storage_account.unity_catalog.name
#   name                 = "ctr${local.prefix}"
# }

# data "azurerm_client_config" "current" {
# }

# // Create the first unity catalog metastore
# resource "databricks_metastore" "this" {
#   name = "primary"
#   storage_root = format("abfss://%s@%s.dfs.core.windows.net/",
#     data.azurerm_storage_container.unity_catalog.name,
#   data.azurerm_storage_account.unity_catalog.name)
#   force_destroy = true
#   # owner         = "account_unity_admin"
# }


# # // Assign managed identity to metastore
# # // AVALIAR COLOCAR ESSE CARA NA PARTE DE FORA
# # resource "databricks_metastore_data_access" "first" {
# #   metastore_id = databricks_metastore.this.id
# #   name         = "the-metastore-key"
# #   azure_managed_identity {
# #     access_connector_id = azurerm_databricks_access_connector.unity.id
# #   }
# #   is_default = true
# #   depends_on = [databricks_grants.this]
# # }


# // Attach the databricks workspace to the metastore
# resource "databricks_metastore_assignment" "this" {
#   workspace_id         = local.databricks_workspace_id
#   metastore_id         = databricks_metastore.this.id
#   default_catalog_name = "hive_metastore"
# }

# locals {
#   aad_groups = toset(var.aad_groups)
# }

# // Read group members of given groups from AzureAD every time Terraform is started
# data "azuread_group" "this" {
#   for_each     = local.aad_groups
#   display_name = each.value
# }

# // Add groups to databricks account
# resource "databricks_group" "this" {
#   provider     = databricks.azure_account
#   for_each     = data.azuread_group.this
#   display_name = each.key
#   external_id  = data.azuread_group.this[each.key].object_id
#   force        = true
# }

# locals {
#   all_members = toset(flatten([for group in values(data.azuread_group.this) : group.members]))
# }

# // Extract information about real users
# data "azuread_users" "users" {
#   ignore_missing = true
#   object_ids     = local.all_members
# }

# locals {
#   all_users = {
#     for user in data.azuread_users.users.users : user.object_id => user
#   }
# }

# // All governed by AzureAD, create or remove users to/from databricks account
# resource "databricks_user" "this" {
#   provider     = databricks.azure_account
#   for_each     = local.all_users
#   user_name    = lower(local.all_users[each.key]["user_principal_name"])
#   display_name = local.all_users[each.key]["display_name"]
#   active       = local.all_users[each.key]["account_enabled"]
#   external_id  = each.key
#   force        = true
#   # disable_as_user_deletion = true # default behavior

#   // Review warning before deactivating or deleting users from databricks account
#   // https://learn.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/scim/#add-users-and-groups-to-your-azure-databricks-account-using-azure-active-directory-azure-ad
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# // Extract information about service prinicpals users
# data "azuread_service_principals" "spns" {
#   object_ids = toset(setsubtract(local.all_members, data.azuread_users.users.object_ids))
# }

# locals {
#   all_spns = {
#     for sp in data.azuread_service_principals.spns.service_principals : sp.object_id => sp
#   }
# }

# // All governed by AzureAD, create or remove service to/from databricks account
# resource "databricks_service_principal" "sp" {
#   provider       = databricks.azure_account
#   for_each       = local.all_spns
#   application_id = local.all_spns[each.key]["application_id"]
#   display_name   = local.all_spns[each.key]["display_name"]
#   active         = local.all_spns[each.key]["account_enabled"]
#   external_id    = each.key
#   force          = true
# }

# locals {
#   account_admin_members = toset(flatten([for group in values(data.azuread_group.this) : [group.display_name == "account_unity_admin" ? group.members : []]]))
# }

# # Extract information about real account admins users
# data "azuread_users" "account_admin_users" {
#   ignore_missing = true
#   object_ids     = local.account_admin_members
# }

# locals {
#   all_account_admin_users = {
#     for user in data.azuread_users.account_admin_users.users : user.object_id => user
#   }
# }

# // Making all users on account_unity_admin group as databricks account admin
# resource "databricks_user_role" "account_admin" {
#   provider   = databricks.azure_account
#   for_each   = local.all_account_admin_users
#   user_id    = databricks_user.this[each.key].id
#   role       = "account_admin"
#   depends_on = [databricks_group.this, databricks_user.this, databricks_service_principal.sp]
# }
