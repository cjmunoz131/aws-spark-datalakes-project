data "aws_caller_identity" "current" {}

resource "random_password" "header_cf_apigateway" {
  length = 20
}

module "aws_security_keys_kms_layer_module" {
  source   = "./modules/aws/aws-security-keys-kms"
  key_name = var.key_name
}

module "aws_security_keys_kms_datasource_layer_module" {
  providers = {
    aws = aws.shared_provider
  }
  source   = "./modules/aws/aws-security-keys-kms"
  key_name = var.key_datasource_name
}

module "aws_security_keys_kms_iam_datasource_layer_module" {
  providers = {
    aws = aws.shared_provider
  }
  source = "./modules/aws/aws-security-keys-kms-iam"
  cross_target_accounts_roles = [{
    account   = var.development_account,
    role_name = var.datasync_source_location_role
  }]
  kms_key_id = module.aws_security_keys_kms_datasource_layer_module.kms_key_id
}

module "aws_security_keys_kms_iam_layer_module" {
  source     = "./modules/aws/aws-security-keys-kms-iam"
  kms_key_id = module.aws_security_keys_kms_layer_module.kms_key_id
}

module "aws_data_storage_datalake_s3_layer_module" {
  source      = "./modules/aws/aws-data-storage-datalake-s3"
  kms_key_arn = module.aws_security_keys_kms_layer_module.kms_key_arn
}

module "aws_storage_datasource_s3_layer_module" {
  providers = {
    aws = aws.shared_provider
  }
  source                          = "./modules/aws/aws-storage-datasource-s3"
  kms_key_arn                     = module.aws_security_keys_kms_datasource_layer_module.kms_key_arn
  bucket_assests_name             = var.assests_bucket_name
  datasync-s3-source-role         = var.datasync_source_location_role
  source_location_s3_subdirectory = var.source_location_s3_subdirectory
  cross_target_accounts_roles = [{
    account   = var.development_account,
    role_name = var.datasync_source_location_role
    },
    {
      account   = var.development_account,
      role_name = "terraform-role"
  }]
}

module "aws_networking_base_vpc_layer_module" {
  source                     = "./modules/aws/aws-networking-base-vpc"
  cidr_block                 = var.vpc_base_cidr_block
  cidr_block_subnet_public   = var.subnet_public_cidr_blocks
  cidr_block_subnet_private  = var.subnet_private_cidr_blocks
  cidr_block_subnet_database = var.subnet_database_cidr_blocks
  availability_zones         = var.availability_zones
  region                     = var.region
  vpc_name                   = var.vpc_name
}

module "aws_networking_integration_vpc_layer_module" {
  source                    = "./modules/aws/aws-networking-integration-vpc"
  vpc_workloads_id          = module.aws_networking_base_vpc_layer_module.vpc_workloads_id
  region                    = var.region
  vpc_s3_rt_integration     = [module.aws_networking_base_vpc_layer_module.private_route_table_id]
  integration_subnets_assoc = module.aws_networking_base_vpc_layer_module.subnet_database_ids
}

module "aws_data_collection_datasync_layer_module" {
  source                                   = "./modules/aws/aws-data-collection-datasync"
  s3_datasource_arn                        = module.aws_storage_datasource_s3_layer_module.blob_media_bucket_s3_arn
  s3_datalake_arn                          = module.aws_data_storage_datalake_s3_layer_module.s3_bucket_arn
  kms_key_arn                              = module.aws_security_keys_kms_layer_module.kms_key_arn
  kms_key_source_arn                       = module.aws_security_keys_kms_datasource_layer_module.kms_key_arn
  datasync_collector_name                  = var.datasync_collector_name
  datasync_source_location_s3_subdirectory = var.source_location_s3_subdirectory
  datasync_target_location_s3_subdirectory = var.target_location_s3_subdirectory
  datasync_source_location_role            = var.datasync_source_location_role
  datasync_target_location_role            = var.datasync_target_location_role
}

module "aws_data_security_glue_layer_module" {
  source             = "./modules/aws/aws-data-security-glue"
  kms_key_arn        = module.aws_security_keys_kms_layer_module.kms_key_arn
  s3_bucket_arn      = module.aws_data_storage_datalake_s3_layer_module.s3_bucket_arn
  glue_database_name = var.glue_database
  glue_table_prefix  = var.glue_table_prefix
  glue_connection_requirements = {
    availability_zone      = "${var.region}${element(var.availability_zones, 0)}",
    security_group_id_list = [module.aws_networking_integration_vpc_layer_module.vpc_s3_endpoint_sg],
    subnet_id              = module.aws_networking_base_vpc_layer_module.subnet_private_ids[0]
  }
  glue_connection_name = var.glue_connection_name
}

module "aws_data_registry_datacatalog_glue_layer_module" {
  source                        = "./modules/aws/aws-data-registry-datacatalog-glue"
  customers_landing_path        = "s3://${module.aws_data_storage_datalake_s3_layer_module.s3_bucket_name}${var.target_location_s3_subdirectory}${var.customer_landing_path}"
  table_prefix                  = var.glue_table_prefix
  step_trainer_path             = "s3://${module.aws_data_storage_datalake_s3_layer_module.s3_bucket_name}${var.target_location_s3_subdirectory}${var.step_training_landing_path}"
  glue-database                 = var.glue_database
  security_configuration_name   = module.aws_data_security_glue_layer_module.aws_glue_security_configuration_name
  crawler_datalake_landing_role = module.aws_data_security_glue_layer_module.glue_role_arn
  network_s3_connection_name    = module.aws_data_security_glue_layer_module.glue_connection_name
  accelerometer_landing_path    = "s3://${module.aws_data_storage_datalake_s3_layer_module.s3_bucket_name}${var.target_location_s3_subdirectory}${var.accelerometer_landing_path}"
  stedy_dl_landing_crawler_name = var.landing_crawler_name
}

module "aws_data_analytics_athena_layer_module" {
  source                           = "./modules/aws/aws-data-analytics-athena"
  kms_key_arn                      = module.aws_security_keys_kms_layer_module.kms_key_arn
  step-tainer_landing_table_name   = var.step-trainer_landing_table_name
  accelerometer_landing_table_name = var.accelerometer_landing_table_name
  glue_catalog_database_name       = module.aws_data_registry_datacatalog_glue_layer_module.glue_database_name
  s3_bucket_name                   = module.aws_data_storage_datalake_s3_layer_module.s3_bucket_name
  customers_landing_table_name     = var.customer_landing_table_name
  step-trainer_landing_path        = "${var.target_location_s3_subdirectory}${var.step_training_landing_path}"
  customers_landing_path           = "${var.target_location_s3_subdirectory}${var.customer_landing_path}"
  accelerometer_landing_path       = "${var.target_location_s3_subdirectory}${var.accelerometer_landing_path}"
}
