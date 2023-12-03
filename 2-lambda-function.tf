#Lambda Policy

resource "aws_iam_role" "order_lambda_exec" {
  name = "order-lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "order_lambda_policy" {
  role       = aws_iam_role.order_lambda_exec.name
  policy_arn = aws_iam_policy.order_lambda_combined.arn
}

resource "aws_iam_policy" "order_lambda_combined" {
  name        = "order_lambda_combined_policy"
  description = "Combined policy for the Order Lambda function"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "lambda:InvokeFunction",
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:CreateAlias",
          "lambda:GetFunction",
          "rds:CreateDBInstance",
          "rds:CreateDBInstanceReadReplica",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:RestoreDBInstanceFromDBSnapshot",
          "rds:RestoreDBInstanceToPointInTime",
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:Describe*",
          "rds:List*",
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "rds-data:ExecuteSql",
          "sns:Publish",
          "sns:Subscribe",
          "other:custom_action",
        ],
        Effect   = "Allow",
        Resource = [
          "*",  # Allow all resources for actions that support wildcard
        ],
      },
    ],
  })
}


# Create Order Lmabda Function Config
resource "aws_lambda_function" "createOrder" {
  function_name = "createOrder"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_createOrder.key

  runtime = "nodejs16.x"
  handler = "function.handler"

  source_code_hash = data.archive_file.lambda_createOrder.output_base64sha256

  role = aws_iam_role.order_lambda_exec.arn

  environment {
    variables = {
      PRODUCE_SNS_TOPIC = aws_sns_topic.sns_process_order.arn
      RDS_HOST = aws_db_instance.testDb.address
      RDS_PORT = aws_db_instance.testDb.port
      RDS_DATABASE = var.db_database
      RDS_USERNAME = aws_db_instance.testDb.username
      RDS_PASSWORD = var.db_password
    }
  }
}

resource "aws_cloudwatch_log_group" "order" {
  name = "/aws/lambda/${aws_lambda_function.createOrder.function_name}"

  retention_in_days = 14
}

data "archive_file" "lambda_createOrder" {
  type = "zip"

  source_dir  = "./${path.module}/functions/createOrder"
  output_path = "./${path.module}/functions/createOrder.zip"
}

resource "aws_s3_object" "lambda_createOrder" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "createOrder.zip"
  source = data.archive_file.lambda_createOrder.output_path

  etag = filemd5(data.archive_file.lambda_createOrder.output_path)
}

# Process Order Lambda Config

resource "aws_lambda_function" "processOrder" {
  function_name = "processOrder"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_processOrder.key

  runtime = "nodejs16.x"
  handler = "function.handler"

  source_code_hash = data.archive_file.lambda_processOrder.output_base64sha256

  role = aws_iam_role.order_lambda_exec.arn

  environment {
    variables = {
      PRODUCE_SNS_TOPIC = aws_sns_topic.sns_update_stock.arn
      RDS_HOST = aws_db_instance.testDb.address
      RDS_PORT = aws_db_instance.testDb.port
      RDS_DATABASE = var.db_database
      RDS_USERNAME = aws_db_instance.testDb.username
      RDS_PASSWORD = var.db_password
    }
  }
}

resource "aws_cloudwatch_log_group" "processOrder" {
  name = "/aws/lambda/${aws_lambda_function.processOrder.function_name}"

  retention_in_days = 14
}

data "archive_file" "lambda_processOrder" {
  type = "zip"

  source_dir  = "./${path.module}/functions/processOrder"
  output_path = "./${path.module}/functions/processOrder.zip"
}

resource "aws_s3_object" "lambda_processOrder" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "processOrder.zip"
  source = data.archive_file.lambda_processOrder.output_path

  etag = filemd5(data.archive_file.lambda_processOrder.output_path)
}


# Update Stock Lambda Config

resource "aws_lambda_function" "updateStock" {
  function_name = "updateStock"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_updateStock.key

  runtime = "nodejs16.x"
  handler = "function.handler"

  source_code_hash = data.archive_file.lambda_updateStock.output_base64sha256

  role = aws_iam_role.order_lambda_exec.arn

  environment {
    variables = {
      RDS_HOST = aws_db_instance.testDb.address
      RDS_PORT = aws_db_instance.testDb.port
      RDS_DATABASE = var.db_database
      RDS_USERNAME = aws_db_instance.testDb.username
      RDS_PASSWORD = var.db_password
    }
  }
}

resource "aws_cloudwatch_log_group" "updateStock" {
  name = "/aws/lambda/${aws_lambda_function.updateStock.function_name}"

  retention_in_days = 14
}

data "archive_file" "lambda_updateStock" {
  type = "zip"

  source_dir  = "./${path.module}/functions/updateStock"
  output_path = "./${path.module}/functions/updateStock.zip"
}

resource "aws_s3_object" "lambda_updateStock" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "updateStock.zip"
  source = data.archive_file.lambda_updateStock.output_path

  etag = filemd5(data.archive_file.lambda_updateStock.output_path)
}

# Get Orders Lambda Config

resource "aws_lambda_function" "getOrder" {
  function_name = "getOrder"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_getOrder.key

  runtime = "nodejs16.x"
  handler = "function.handler"

  source_code_hash = data.archive_file.lambda_getOrder.output_base64sha256

  role = aws_iam_role.order_lambda_exec.arn

  environment {
    variables = {
      RDS_HOST = aws_db_instance.testDb.address
      RDS_PORT = aws_db_instance.testDb.port
      RDS_DATABASE = var.db_database
      RDS_USERNAME = aws_db_instance.testDb.username
      RDS_PASSWORD = var.db_password
    }
  }
}

resource "aws_cloudwatch_log_group" "getOrder" {
  name = "/aws/lambda/${aws_lambda_function.getOrder.function_name}"

  retention_in_days = 14
}

data "archive_file" "lambda_getOrder" {
  type = "zip"

  source_dir  = "./${path.module}/functions/getOrder"
  output_path = "./${path.module}/functions/getOrder.zip"
}

resource "aws_s3_object" "lambda_getOrder" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "getOrder.zip"
  source = data.archive_file.lambda_getOrder.output_path

  etag = filemd5(data.archive_file.lambda_getOrder.output_path)
}

# Create Table Lambda Config
resource "aws_lambda_function" "addTables" {
  function_name = "addTables"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_addTables.key

  runtime = "nodejs16.x"
  handler = "function.handler"

  source_code_hash = data.archive_file.lambda_addTables.output_base64sha256

  role = aws_iam_role.order_lambda_exec.arn

  environment {
    variables = {
      RDS_HOST = aws_db_instance.testDb.address
      RDS_PORT = aws_db_instance.testDb.port
      RDS_DATABASE = var.db_database
      RDS_USERNAME = aws_db_instance.testDb.username
      RDS_PASSWORD = var.db_password
    }
  }
}

resource "aws_cloudwatch_log_group" "orderTable" {
  name = "/aws/lambda/${aws_lambda_function.addTables.function_name}"

  retention_in_days = 14
}

data "archive_file" "lambda_addTables" {
  type = "zip"

  source_dir  = "./${path.module}/functions/addTables"
  output_path = "./${path.module}/functions/addTables.zip"
}

resource "aws_s3_object" "lambda_addTables" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "addTables.zip"
  source = data.archive_file.lambda_addTables.output_path

  etag = filemd5(data.archive_file.lambda_addTables.output_path)
}

resource "null_resource" "addTables" {
  triggers = {
    rds_instance_id = aws_db_instance.testDb.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws lambda invoke --region=us-east-1 --function-name=addTables response.json
    EOT
  }
}
