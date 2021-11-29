terraform {
  backend "s3" {
    key    = "terraform/christmas-list/statefile"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "create_list_role" {
  name = "create_list_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_lambda_layer_version" "create_list_libs" {
  filename   = "./dist/libs.zip"
  layer_name = "create_list_libs"
  source_code_hash = filebase64sha256("./dist/libs.zip")

  compatible_runtimes = ["python3.8"]
}


resource "aws_lambda_function" "create_list" {
  filename      = "./dist/deploy.zip"
  function_name = "create-list"
  role          = aws_iam_role.create_list_role.arn
  handler       = "handler.create_list"
  source_code_hash = filebase64sha256("./dist/deploy.zip")
  runtime = "python3.8"
  memory_size = 256
  timeout = 600
  layers = ["${aws_lambda_layer_version.create_list_libs.arn}"]
}
