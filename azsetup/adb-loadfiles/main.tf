
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

provider "azurerm" {
  features {}
}

data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group
}

locals {
  databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url
}

// Provider for databricks workspace
provider "databricks" {
  host = local.databricks_workspace_host
}

// Provider for databricks account
provider "databricks" {
  alias               = "azure_account"
  host                = "https://accounts.azuredatabricks.net"
  account_id          = var.account_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret
  azure_tenant_id     = var.azure_tenant_id
  auth_type           = "azure-client-secret"
}


variable "job_name" {
  description = "A name for the job."
  type        = string
  default     = "My Job"
}

variable "task_key" {
  description = "A name for the task."
  type        = string
  default     = "my_task"
}

resource "databricks_job" "this" {
  name = var.job_name
  task {
    task_key = var.task_key
    existing_cluster_id = "0818-224929-8yz5wq7p"
    notebook_task {
      notebook_path = "/Workspace/Users/douglas.sleal@outlook.com/load_message_files"
    }
  }

  schedule {
    quartz_cron_expression = "*/2 * * * *" # cron schedule of job
    timezone_id = "UTC"
  }
}

output "job_url" {
  value = databricks_job.this.url
}
