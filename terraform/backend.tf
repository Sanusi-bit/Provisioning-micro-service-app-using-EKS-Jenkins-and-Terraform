terraform {
  backend "s3" {
    region = "eu-west-2"
    bucket = "altschool-bucket"
    key = "s3-bucket/terraform.tfstate"
    dynamodb_table = "dynamodb-table"
    encrypt = true
  }
}