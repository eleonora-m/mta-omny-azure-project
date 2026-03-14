variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "rg-mta-omny-prod-v5" # Ставим v5 для чистого старта
}

variable "location" {
  description = "Azure region for resources"
  default     = "eastus" # Match existing resource group location
}

variable "project_name" {
  description = "Project prefix for resources"
  default     = "omny-fare-system"
}