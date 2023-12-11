output "glue_catalog_database_name" {
  description = "name of the glue catalog database"
  value       = aws_glue_catalog_database.cidazure.name
}

output "glue_catalog_table_name" {
  description = "name of the glue catalog table"
  value       = aws_glue_catalog_table.cidazure.name
}

output "glue_iam_role_arn" {
  description = "arn of the glue iam role"
  value       = aws_iam_role.GlueIAM.arn
}

output "glue_iam_role_id" {
  description = "id of the glue iam role"
  value       = aws_iam_role.GlueIAM.id
}