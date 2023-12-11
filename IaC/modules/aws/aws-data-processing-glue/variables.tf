# Common Settings
variable "PrefixCode" {
  description = "Prefix used to name all resources created by this CloudFormation template. Use 3 alphanumeric characters only. Cannot be 'aws'. e.g. department name, business unit, project name"
  type        = string
  default     = "etl"
}

variable "GlueCopySchedule" {
  description = "Scheduled time (UTC) for Glue data processing. Must be a CRON expression. The default sets the schedule to 4am daily. Must be after Azure data pull above"
  type        = string
  default     = "cron(0 4 * * ? *)"
}

variable "s3_bucket_arn" {
  description = "bucket arn"
  type        = string
}

variable "s3_bucket_name" {
  description = "bucket name"
  type        = string
}

variable "s3_bucket_id" {
  description = "bucket id"
  type        = string
}

variable "glue_job_iam_role_arn" {
  description = "IAM role for the glue job"
  type        = string
}

variable "security_configuration_name" {
  type        = string
  description = "security configuration name"
}

variable "date_format" {
  type        = string
  description = "date format for customer data"
}

variable "glue_catalog_database_name" {
  type        = string
  description = "database name of the glue catalog"
}

variable "glue_catalog_table_customers_landing_name" {
  type        = string
  description = "table name"
}

variable "trusted_folder" {
  type        = string
  description = "trusted folder for customers"
}

variable "customers_folder" {
  type        = string
  description = "customers folder"
}

variable "landing_folder" {
  type        = string
  description = "landing folder for customers"
}