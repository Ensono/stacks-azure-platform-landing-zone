#------------------------------------------------------------------------------
# Key Vault Module Variables
#------------------------------------------------------------------------------

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "deployment_principal_id" {
  description = "Object ID of the deployment service principal for RBAC"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet resource ID for the private endpoint"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
