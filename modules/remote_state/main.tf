terraform {
    required_version = ">=0.14.8"
}

# Define the resource group for hosting the storage account
resource "azurerm_resource_group" "demo" {
  name     = var.rg_name                   # We need to declare this as a variable in the modules variables.tf
  location = var.rg_location               # We need to declare this as a variable in the modules variables.tf
  tags = merge(
    var.tags, {                            # We need to declare this as a variable in the modules variables.tf
      Name = "var.rg_name"
  })
}
resource "random_integer" "stacc_num" {
  min = var.random_min                        # We need to declare this as a variable in the modules variables.tf
  max = var.random_max                        # We need to declare this as a variable in the modules variables.tf
}

resource "azurerm_storage_account" "stacc" {
  name                     = "${lower(var.stacc_name_prefix)}${random_integer.stacc_num.result}"     # We need to declare this as a variable in the modules variables.tf
  resource_group_name      = azurerm_resource_group.demo.name
  location                 = var.rg_location     # We have already declared this variable
  account_tier             = var.acc_tier        # We need to declare this as a variable in the modules variables.tf
  account_replication_type = var.acc_rep_type    # We need to declare this as a variable in the modules variables.tf
}
resource "azurerm_storage_container" "ct" {
  name                 = var.container_name      # We need to declare this as a variable in the modules variables.tf
  storage_account_name = azurerm_storage_account.stacc.name
}
data "azurerm_storage_account_sas" "state" {
  connection_string = azurerm_storage_account.stacc.primary_connection_string
  https_only        = true
  resource_types {
    service   = true
    container = true
    object    = true
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  start = var.sas_start     # We need to declare this as a variable in the modules variables.tf
  expiry = timeadd(var.sas_start, var.sas_timeadd) # We need to declare this as a variable in the modules variables.tf

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = false
    process = false
  }
}
resource "null_resource" "post-deploy" {
  depends_on = [azurerm_storage_container.ct]     # We need to ensure the container exists before providing the output
  provisioner "local-exec" {
  command = <<EOT
  echo 'storage_account_name = "${azurerm_storage_account.stacc.name}"' >> ${var.sas_output_file} # variable we need to define
  echo 'container_name = "tf-state"' >> ${var.sas_output_file}
  echo 'key = "terraform.tfstate"' >> ${var.sas_output_file}
  echo 'sas_token = "${data.azurerm_storage_account_sas.state.sas}"' >> ${var.sas_output_file}
  EOT
}
}