variable "ProductDomain" {
  description = "Identifies the product group and associated development team."
  type        = string
  validation {
    condition = contains([
      "Buy",
      "Enterprise",
      "Architecture",
      "Move",
      "Retail",
      "Digital",
      "Know"
    ], var.ProductDomain)
    error_message = "ProductDomain must be one of: Buy, Enterprise, Architecture, Move, Retail, Digital, Know."
  }
}

variable "Application" {
  description = "Identifies the application related to the resource."
  type        = string
}

variable "ApplicationCode" {
  description = "Links the application to the approved application list."
  type        = string
}

variable "Environment" {
  description = "Product lifecycle stage."
  type        = string
  validation {
    condition = contains([
      "Development",
      "Test",
      "Production"
    ], var.Environment)
    error_message = "Environment must be one of: Development, Test, Production."
  }
}

variable "Role" {
  description = "Roles of service"
  type        = string
}

variable "Criticality" {
  description = "Denotes the importance of a service and availability requirement. E.g. Low (95%), Medium (99.5%), High (99.9%) and Critical (99.95%)"
  type        = string
  validation {
    condition = contains([
      "Low",
      "Medium",
      "High",
      "Critical"
    ], var.Criticality)
    error_message = "Criticality must be one of: Low, Medium, High, Critical."
  }
}

variable "CostCode" {
  description = "The date the ARM deployment for the resource occurred, for example “2019-08-27T16:30:10.7936410+01:00”.(The use of the UTC time zone is recommended for consistency)"
  type        = string
}

variable "Owner" {
  description = "TBusiness Owner of the Resource Group/Resource."
  type        = string
}

variable "CreatedOn" {
  description = "The date the ARM deployment for the resource occurred, for example “2019-08-27T16:30:10.7936410+01:00”.(The use of the UTC time zone is recommended for consistency)."
  type        = string
}

variable "CreatedBy" {
  description = "Email address of the engineer who provisioned the resource."
  type        = string
}

variable "Monitoring" {
  description = "The monitoring solution used."
  type        = string
}
