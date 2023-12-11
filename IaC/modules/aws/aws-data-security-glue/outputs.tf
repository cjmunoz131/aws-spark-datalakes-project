output "aws_glue_security_configuration_name" {
  value = aws_glue_security_configuration.glue_securityconfig_stedi.name
}

output "glue_connection_name" {
  value = aws_glue_connection.glue_connection.name
}

output "glue_role_arn" {
  value = aws_iam_role.GlueIAM.arn
}