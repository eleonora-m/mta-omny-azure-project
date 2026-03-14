variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "rg-mta-omny-prod-v4" # Меняем версию, чтобы создать с чистого листа
}

variable "location" {
  description = "Azure region for resources"
  default     = "East US 2" 
}

variable "project_name" {
  description = "Project prefix for resources"
  default     = "omny-fare-system"
}