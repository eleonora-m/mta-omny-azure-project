variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-mta-omny-prod-v5"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus" 
}

variable "project_name" {
  description = "Prefix for all resources"
  type        = string
  default     = "omny-fare-system"
}