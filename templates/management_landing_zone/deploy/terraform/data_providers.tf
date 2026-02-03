# Use azapi_client_config for management groups - returns known values at plan time
# (unlike azurerm_client_config which may have unknown values causing for_each issues)
data "azapi_client_config" "current" {}
