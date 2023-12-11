data "aws_caller_identity" "current" {}

### Create IAM configuration used throughout project
resource "aws_iam_role" "GlueIAM" {
  name        = format("%s-%s-%s", "iar", terraform.workspace, "stedi-glue")
  description = "Stedi project IAM role for Glue"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name  = format("%s-%s-%s", "iar", terraform.workspace, "stedi-glue")
    rtype = "security"
  }
}

resource "aws_iam_role_policy" "GlueIAM" {
  name = format("%s-%s-%s", "irp", terraform.workspace, "stedi-glue")
  role = aws_iam_role.GlueIAM.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:UpdateDatabase",
          "glue:UpdateTable",
          "glue:UpdatePartition",
          "glue:BatchCreatePartition",
          "glue:CreatePartition",
          "glue:CreateTable",
          "glue:GetSecurityConfiguration",
          "glue:GetConnection"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:glue:${var.Region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.Region}:${data.aws_caller_identity.current.account_id}:database/${var.glue_database_name}",
          "arn:aws:glue:${var.Region}:${data.aws_caller_identity.current.account_id}:table/${var.glue_database_name}/${var.glue_table_prefix}*",
          "${aws_glue_connection.glue_connection.arn}"
        ]
      },
      {
        Action = [
          "glue:GetSecurityConfiguration"
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
        # Condition = {
        #     "StringEquals": {
        #       "glue:ResourceTag/ConnectionName": "${aws_glue_security_configuration.glue_securityconfig_stedi.id}"
        #   }
        # }
      },
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
        ]
        Effect = "Allow"
        Resource = [
          "${var.s3_bucket_arn}",
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:ReEncrypt*",
          "kms:Describe*",
          "kms:GetPublicKey",
          "kms:ListAliases",
        ]
        Effect = "Allow"
        Resource = [
          "${var.kms_key_arn}"
        ]
      },
      {
        Action = [
          "logs:AssociateKmsKey",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:logs:${var.Region}:${data.aws_caller_identity.current.account_id}:log-group:*"
        ]
      },
      {
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:ssm:${var.Region}:${data.aws_caller_identity.current.account_id}:parameter/stedi*"
        ]
      },
      {
        Action = [
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeRouteTables",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcAttribute",
          "iam:ListRolePolicies",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRoles",
          "iam:ListAttachedRolePolicies",
          "cloudwatch:PutMetricData"
        ]
        Effect = "Allow"
        Resource = [
          "*"
        ]
      },
      {
        Action = [
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:security-group/*",
          "arn:aws:ec2:*:*:instance/*"
        ],
        Condition = {
          "ForAllValues:StringEquals" : {
            "aws:TagKeys" : [
              "aws-glue-service-resource"
            ]
          }
        }
      },
      {
        Action = [
          "iam:PassRole"
        ],
        Effect = "Allow",
        Resource = [
          "arn:aws:iam::*:role/service-role/AWSGlueServiceRole*"
        ],
        Condition = {
          "StringLike" : {
            "iam:PassedToService" : [
              "glue.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# resource "aws_security_group" "glue_connection_sg" {
#   name        = "glue_connection_sg"
#   description = "Allow traffic on port 443 from vpcendpoints services"
#   vpc_id      = var.vpc_workloads_id

#   ingress {
#     from_port   = "443"
#     to_port     = "443"
#     protocol    = "all"
#     description = "TLS Port for S3"
#     cidr_blocks = ["0.0.0.0/0"]

#   }

#   ingress {
#     from_port = "0"
#     to_port = "0"
#     protocol = "-1"
#     self = true
#   }

#   egress {
#     from_port   = "0"
#     to_port     = "0"
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "allows connection to dynamodb vpc endpoint"
#   }

#   tags = {
#     Name = "glue_connection_sg"
#   }
# }

resource "aws_glue_security_configuration" "glue_securityconfig_stedi" {
  name = format("%s-%s-%s", "glx", terraform.workspace, "stedi-glue")

  encryption_configuration {
    cloudwatch_encryption {
      kms_key_arn                = var.kms_key_arn
      cloudwatch_encryption_mode = "SSE-KMS"
    }

    job_bookmarks_encryption {
      kms_key_arn                   = var.kms_key_arn
      job_bookmarks_encryption_mode = "CSE-KMS"
    }

    s3_encryption {
      kms_key_arn        = var.kms_key_arn
      s3_encryption_mode = "SSE-KMS"
    }
  }
}



resource "aws_glue_connection" "glue_connection" {
  name            = format("%s-%s-%s", "glx", terraform.workspace, var.glue_connection_name)
  description     = "glue connection to connect privately to S3 datalake"
  connection_type = "NETWORK"

  physical_connection_requirements {
    availability_zone = var.glue_connection_requirements.availability_zone
    # security_group_id_list = [aws_security_group.glue_connection_sg.id]
    security_group_id_list = var.glue_connection_requirements.security_group_id_list
    subnet_id              = var.glue_connection_requirements.subnet_id
  }

  lifecycle {
    create_before_destroy = true
  }
}