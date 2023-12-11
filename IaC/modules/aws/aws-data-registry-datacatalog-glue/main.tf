### Create Glue Resources
resource "aws_glue_catalog_database" "stedi-glue-catalog" {
  name        = var.glue-database
  description = "Glue catalog database used to process the data of the stedi project"
}

resource "aws_glue_crawler" "stedy_dl_landing_crawler" {
  name          = var.stedy_dl_landing_crawler_name
  database_name = aws_glue_catalog_database.stedi-glue-catalog.name
  role          = var.crawler_datalake_landing_role
  table_prefix  = var.table_prefix
  description   = "stedi_project_landing_crawler"

  security_configuration = var.security_configuration_name

  schema_change_policy {
    delete_behavior = "LOG"
  }

  s3_target {
    path            = var.accelerometer_landing_path
    connection_name = var.network_s3_connection_name
  }

  s3_target {
    path            = var.customers_landing_path
    connection_name = var.network_s3_connection_name
  }

  s3_target {
    path            = var.step_trainer_path
    connection_name = var.network_s3_connection_name
  }
}