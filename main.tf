provider "azurerm" {
  features {}
}
module "azure_remote_state" {
  source            = "./modules/remote_state"               # Where it the module located
  random_min        = 100000                                 # Minimum value for our random integer
  random_max        = 999999                                 # Maximum value for our random integer
  rg_name           = "demo-rg"                              # Name for the Azure Resource Group
  rg_location       = "UK West"                              # Geographic location for our Azure Resource Group
  stacc_name_prefix = "demonstration"                        # Prefix for our storage account - Random integer will be appended
  acc_tier          = "standard"                             # Azure Storage Account Tier
  acc_rep_type      = "LRS"                                  # Azure Storage Redundancy
  container_name    = "tf-state"                             # Azure Storage Account Container Name
  sas_start         = timestamp()   #"2021-03-30T07:00:00Z"  # Starting time for the SAS Token including req. format
  sas_timeadd       = "48h"                                  # Duration from starting time when SAS Token will expire
  sas_output_file   = "sas-remote-state.txt"                 # Output file containing all the information we need to move to remove state
}