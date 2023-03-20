data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "tf_backend_bucket" {
  bucket = "altschool-bucket"
  acl    = "private"
  versioning {
    enabled = true
  }

  tags = {
    Name        = "altschool-bucket"
    Environment = "Dev"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_master_key_id
        sse_algorithm     = var.kms_master_key_id == "" ? "AES256" : "aws:kms"
      }
    }
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_dynamodb_table" "basic-dynamodb-table" {
  count = var.aws_dynamodb_table_enabled ? 1 : 0
  name           = "dynamodb-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = var.read_capacity
  write_capacity = var.write_capacity
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "dynamodb-table"
    Environment = "production"
  }
  
  lifecycle {
    prevent_destroy = false
  }

}

data "aws_iam_policy_document" "tf_backend_bucket_policy" {
  statement {
    sid = "1"
    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.tf_backend_bucket.arn}/*",
      "${aws_s3_bucket.tf_backend_bucket.arn}"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        false,
      ]
    }

    principals {
      type = "*"
      identifiers = [ "*" ]
    }
  }

  statement {
    sid = "RequireEncryptedStorage"
    effect = "Deny"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.tf_backend_bucket.arn}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        var.kms_master_key_id == "" ? "AES256" : "aws:kms"
      ]
    }

    principals {
      type = "*"
      identifiers = [ "*" ]
    }
  }
}


resource "aws_s3_bucket_policy" "tf_backend_policy" {
  bucket = aws_s3_bucket.tf_backend_bucket.id
  policy = data.aws_iam_policy_document.tf_backend_bucket_policy.json
}