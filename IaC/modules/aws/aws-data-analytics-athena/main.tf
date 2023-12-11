### Create Athena resources
resource "aws_athena_workgroup" "stedi-analytics-wg" {
  name          = format("%s-%s-%s", "atw", terraform.workspace, "stedi")
  description   = "STEDI Athena Workgroup"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.s3_bucket_name}/resultqueries"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = var.kms_key_arn
      }
    }
  }

  tags = {
    Name = format("%s-%s-%s", "atw", terraform.workspace, "stedi-glue")
  }
}

### Generate Athena saved query. named query is for reference only and not used as part of automation
resource "aws_athena_named_query" "customer_landing_table_creation" {
  name        = format("%s-%s-%s-%s", "atq", terraform.workspace, "stedi", "customer_landing_table_creation")
  description = "Create customer landing table definition DDL"
  workgroup   = aws_athena_workgroup.stedi-analytics-wg.id
  database    = var.glue_catalog_database_name
  query = templatefile("${path.root}/../data_dev/src/athena/customer_landing.sql", {
    customers_landing_table = "${var.customers_landing_table_name}",
    datalake_bucket_name    = "${var.s3_bucket_name}",
    customers_landing_path  = "${var.customers_landing_path}"
  })
}

resource "aws_athena_named_query" "accelerometer_landing_table_creation" {
  name        = format("%s-%s-%s-%s", "atq", terraform.workspace, "stedi", "accelerometer_landing_table_creation")
  description = "Create accelerometer landing table definition DDL"
  workgroup   = aws_athena_workgroup.stedi-analytics-wg.id
  database    = var.glue_catalog_database_name
  query = templatefile("${path.root}/../data_dev/src/athena/accelerometer_landing.sql", {
    accelerometer_landing_table = "${var.accelerometer_landing_table_name}",
    datalake_bucket_name        = "${var.s3_bucket_name}",
    accelerometer_landing_path  = "${var.accelerometer_landing_path}"
  })
}

resource "aws_athena_named_query" "step-trainer_landing_table_creation" {
  name        = format("%s-%s-%s-%s", "atq", terraform.workspace, "stedi", "step-trainer_landing_table_creation")
  description = "Create step-trainer landing table definition DDL"
  workgroup   = aws_athena_workgroup.stedi-analytics-wg.id
  database    = var.glue_catalog_database_name
  query = templatefile("${path.root}/../data_dev/src/athena/step_trainer_landing.sql", {
    step-trainer_landing_table = "${var.step-tainer_landing_table_name}",
    datalake_bucket_name       = "${var.s3_bucket_name}",
    step-trainer_landing_path  = "${var.step-trainer_landing_path}"
  })
}