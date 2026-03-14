variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "rg-mta-omny-prod-v3"
}

variable "location" {
  description = "Azure region for resources"
  default     = "Canada Central"
}

variable "project_name" {
  description = "Project prefix for resources"
  default     = "omny-fare-system"
}