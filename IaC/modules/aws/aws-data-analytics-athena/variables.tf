variable "kms_key_arn" {
  type        = string
  description = "kms key arn"
}

variable "s3_bucket_name" {
  type        = string
  description = "name of the bucket where querys results are stored"
}

variable "glue_catalog_database_name" {
  type        = string
  description = "catalog database name"
}

variable "customers_landing_table_name" {
  type        = string
  description = "customers landing table name"
}

variable "accelerometer_landing_table_name" {
  type        = string
  description = "accelerometer landing table name"
}

variable "step-tainer_landing_table_name" {
  type        = string
  description = "step-trainer landing table name"
}

variable "customers_landing_path" {
  type        = string
  description = "landing path for customers data"
}

variable "accelerometer_landing_path" {
  type        = string
  description = "landing path for accelerometer data"
}

variable "step-trainer_landing_path" {
  type        = string
  description = "landing path for step-trainer data"
}