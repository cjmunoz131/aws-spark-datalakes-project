variable "glue_connection_name" {
  description = "connection name for glue crawlers and glue jobs"
  type        = string
}

variable "glue_connection_requirements" {
  type = object({
    availability_zone      = string,
    security_group_id_list = set(string)
    subnet_id              = string
  })
}

variable "Region" {
  description = "region for lambdas deployment"
  type        = string
  default     = "us-east-1"
}

variable "kms_key_arn" {
  description = "arn for kms encryption key"
  type        = string
}

variable "s3_bucket_arn" {
  description = "bucket arn"
  type        = string
}

variable "glue_database_name" {
  description = "glue_database_name"
  type        = string
}

variable "glue_table_prefix" {
  description = "glue tables prefix for the database"
  type        = string
}