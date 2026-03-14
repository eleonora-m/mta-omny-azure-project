variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-mta-omny-v7" # Новое имя, чтобы избежать конфликтов
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "westus" # Смена региона на более свободный
}

variable "project_name" {
  description = "Prefix for all resources"
  type        = string
  default     = "mta-prod"
}