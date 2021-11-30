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

resource "aws_dynamodb_table" "christmas_list_table" {
  name = "ChristmasLists"
  hash_key = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_iam_role" "christmas_list_service_role" {
  name = "christmas_list_service_role"
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

  inline_policy {
    name = "christmas_list_service_dynamodb_policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "dynamodb:BatchGetItem",
            "dynamodb:GetItem",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:BatchWriteItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
          ],
          "Resource" = [
            "${aws_dynamodb_table.christmas_list_table.arn}"
          ]
        }
      ]
    })
  }
}

resource "aws_lambda_layer_version" "christmas_list_service_libs" {
  filename   = "./dist/libs.zip"
  layer_name = "christmas_list_service_libs"
  source_code_hash = filebase64sha256("./dist/libs.zip")

  compatible_runtimes = ["python3.8"]
}


resource "aws_lambda_function" "christmas_list_service" {
  filename      = "./dist/deploy.zip"
  function_name = "christmas-list-service"
  role          = aws_iam_role.christmas_list_service_role.arn
  handler       = "app.lambda_handler"
  source_code_hash = filebase64sha256("./dist/deploy.zip")
  runtime = "python3.8"
  memory_size = 256
  timeout = 600
  layers = ["${aws_lambda_layer_version.christmas_list_service_libs.arn}"]
}

resource "aws_api_gateway_rest_api" "christmas_list_api" {
  name        = "Christmas List API"
  description = "A christmas list api for testing purposes"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.christmas_list_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.christmas_list_api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.christmas_list_api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.christmas_list_api.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.christmas_list_service.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.christmas_list_api.id}"
  resource_id   = "${aws_api_gateway_rest_api.christmas_list_api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.christmas_list_api.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.christmas_list_service.invoke_arn}"
}

resource "aws_api_gateway_deployment" "prod" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.christmas_list_api.id}"
  stage_name  = "prod"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.christmas_list_service.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.christmas_list_api.execution_arn}/*/*"
}