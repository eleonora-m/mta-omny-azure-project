variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-mta-omny-v7"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westus2"
}

variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "mta-prod"
}