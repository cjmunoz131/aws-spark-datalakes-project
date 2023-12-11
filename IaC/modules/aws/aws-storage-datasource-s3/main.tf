data "aws_caller_identity" "current" {}
### Create S3 bucket to receive data
resource "aws_s3_bucket" "S3MediaBucket" {
  # bucket      = format("%s%s%s%s", var.PrefixCode, "sss", var.EnvironmentCode, "azs3copy")
  #bucket_prefix = format("%s%s%s%s", var.PrefixCode, "sss", var.EnvironmentCode, "azs3copy")
  bucket        = format("%s-%s", var.bucket_assests_name, "${data.aws_caller_identity.current.account_id}")
  force_destroy = true

  tags = {
    Name = format("%s-%s", var.bucket_assests_name, "${data.aws_caller_identity.current.account_id}")
  }
}

resource "aws_s3_bucket_policy" "S3Bucket" {
  bucket = aws_s3_bucket.S3MediaBucket.id
  policy = data.aws_iam_policy_document.S3Bucket.json
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.S3MediaBucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
  depends_on = [aws_s3_bucket_public_access_block.S3Bucket]
}


data "aws_iam_policy_document" "S3Bucket" {
  statement {
    sid    = "Allow HTTPS only"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3*"
    ]
    resources = [
      "${aws_s3_bucket.S3MediaBucket.arn}",
      "${aws_s3_bucket.S3MediaBucket.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }

  statement {
    sid    = "Allow TLS 1.2 and above"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3*"
    ]
    resources = [
      "${aws_s3_bucket.S3MediaBucket.arn}",
      "${aws_s3_bucket.S3MediaBucket.arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values = [
        "1.2"
      ]
    }
  }

  statement {
    sid       = "RequireKMSEncryption"
    effect    = "Deny"
    resources = ["${aws_s3_bucket.S3MediaBucket.arn}/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  statement {
    sid       = "RequireSpecificKMSKey"
    effect    = "Deny"
    resources = ["${aws_s3_bucket.S3MediaBucket.arn}/*"]
    actions   = ["s3:PutObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotLikeIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [var.kms_key_arn]
    }
  }

  dynamic "statement" {
    for_each = var.cross_target_accounts_roles

    content {
      sid       = "AllowDataSyncMigration-${statement.value.role_name}"
      effect    = "Allow"
      resources = ["${aws_s3_bucket.S3MediaBucket.arn}", "${aws_s3_bucket.S3MediaBucket.arn}/*"]

      actions = [
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListMultipartUploadParts",
        "s3:PutObjectTagging",
        "s3:GetObjectTagging",
        "s3:PutObject",
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads"
      ]

      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${statement.value.account}:role/${statement.value.role_name}"]
        # identifiers = ["arn:aws:iam::697682206292:role/*"]
      }
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "S3Bucket" {
  bucket = aws_s3_bucket.S3MediaBucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "S3Bucket" {
  bucket = aws_s3_bucket.S3MediaBucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "S3Bucket" {
  bucket                  = aws_s3_bucket.S3MediaBucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


#upload
resource "aws_s3_object" "objects" {
  bucket = aws_s3_bucket.S3MediaBucket.id

  for_each = fileset("../${path.root}/DataSources/starter/", "**/*.*")
  key      = "${var.source_location_s3_subdirectory}/${each.value}"
  source   = "../${path.root}/DataSources/starter/${each.value}"
  # etag         = filemd5("../${path.root}/DataSources/starter/${each.value}")
  content_type = "application/json"
  kms_key_id   = var.kms_key_arn
  depends_on = [
    aws_s3_bucket.S3MediaBucket
  ]
}