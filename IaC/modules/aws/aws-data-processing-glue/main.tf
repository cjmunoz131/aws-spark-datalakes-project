data "aws_caller_identity" "current" {}
### Create IAM configuration used throughout project

resource "aws_glue_trigger" "landing_glue_trigger" {
  name        = format("%s-%s-%s", "glt", terraform.workspace, "stedi-glue")
  description = "Stedi ETL job schedule"
  schedule    = var.GlueCopySchedule
  type        = "SCHEDULED"

  actions {
    job_name = aws_glue_job.customers_trusted_glue_job.name
  }

  tags = {
    Name  = format("%s-%s-%s", "glt", terraform.workspace, "stedi-glue")
    rtype = "data"
  }
}

### Upload Glue Script
resource "aws_s3_object" "customers_trusted_script" {
  bucket = var.s3_bucket_id
  key    = "scripts/customers-trusted.py"
  content = templatefile("${path.root}/../data_dev/src/glue/trusted-zone/customers-trusted.py",
    {
      var_bucket         = var.s3_bucket_id
      var_date_format    = var.date_format
      var_error_folder   = "error"
      var_glue_database  = var.glue_catalog_database_name
      var_glue_table     = var.glue_catalog_table_customers_landing_name
      var_trusted_folder = "${var.customers_folder}/${var.trusted_folder}"
      var_trusted_path   = "s3://${var.s3_bucket_name}/${var.customers_folder}/${var.trusted_folder}/"
      var_landing_folder = "${var.customers_folder}/${var.landing_folder}"
      var_landing_path   = "s3://${var.s3_bucket_name}/${var.customers_folder}/${var.landing_folder}/"
    }
  )
}

resource "aws_glue_job" "customers_trusted_glue_job" {
  name                   = format("%s-%s-%s", var.PrefixCode, "glj", "customers_trusted_glue_job")
  description            = "Glue ETL job for trusted customers"
  role_arn               = var.glue_job_iam_role_arn
  glue_version           = "4.0"
  worker_type            = "G.1X"
  number_of_workers      = 5
  max_retries            = 0
  timeout                = 60
  security_configuration = var.security_configuration_name

  command {
    script_location = "s3://${var.s3_bucket_name}/${aws_s3_object.cidazuregluepy.key}"
    python_version  = "3"
    name            = "glueetl"
  }

  default_arguments = {
    "--enable-glue-datacatalog" = "true"
    "--enable-spark-ui"         = "true"
    "--library-set"             = "analytics"
    "--enable-metrics"          = ""
    "--job-language"            = "python"
    "--enable-job-insights"     = "true"
    "--enable-auto-scaling"     = "true"
    "--job-bookmark-option"     = "job-bookmark-enable"
  }

  tags = {
    Name = format("%s-%s-%s", var.PrefixCode, "glj", "customers_trusted_glue_job")
  }
}