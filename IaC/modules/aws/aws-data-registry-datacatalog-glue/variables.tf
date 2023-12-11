variable "glue-database" {
  type        = string
  description = "database in glue catalog for stedi project"
}

variable "table_prefix" {
  type        = string
  description = "table prefix in the stedi data catalog"
}

variable "crawler_datalake_landing_role" {
  type        = string
  description = "role for the crawler with target s3 datalake"
}

variable "stedy_dl_landing_crawler_name" {
  type        = string
  description = "crawler name"
}

variable "security_configuration_name" {
  type        = string
  description = "security configuration name"
}

variable "network_s3_connection_name" {
  type        = string
  description = "crawler connection type name"
}

variable "accelerometer_landing_path" {
  type        = string
  description = "accelerometer landing path"
}

variable "customers_landing_path" {
  type        = string
  description = "customers landing path"
}

variable "step_trainer_path" {
  type        = string
  description = "step_trainer device landing path"
}
