# PROJECT-MODULE03: Spark and Data Lakes
## Quick Start Instructions

1. Create a IAM user with necessary permissions
2. Create a IAM Role with a trusted policy and the necessary permission sets 
3. Create the variables.tfvars file with number of the deployment accounts
4. Deploy the infraestructure with two accounts, one account with the s3 datasource and the other where is the datalake, terraform init, plan, apply
5. Run the aws Crawlers created by the terraform apply, run the athena querys to create the landing tables.
6. For development, you can init a dev container with the commands specified in the comandos.txt file
7. Execute the jobs deployed in aws glue in order to execute the data processing.


---
## Overview

The project STEDI, is made up by the following:

* The definition of the data architecture, and the Glue processing definition
* The terraform IaC code to deploy all the infraestructure of the project
* Scripts of the amazon athena landing creation tables: data_dev/src/athena/*.sql
* Scripts of the Glue processing Jobs: data_dev/src/glue/*.py

---