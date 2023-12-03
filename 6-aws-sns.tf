# SNS Topics Config

resource "aws_sns_topic" "sns_process_order" {
  name = "sns_process_order"
}

data "aws_sns_topic" "sns_process_order" {
  name = aws_sns_topic.sns_process_order.name
}

resource "aws_sns_topic_policy" "sns_process_order_policy" {
  arn = aws_sns_topic.sns_process_order.arn

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "SNS:Publish",
        "SNS:Subscribe",
        "SNS:Receive"
      ],
      "Resource": "${aws_sns_topic.sns_process_order.arn}"
    }
  ]
}
EOF
}


resource "aws_sns_topic_subscription" "process_order_subscription" {
  topic_arn = aws_sns_topic.sns_process_order.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.processOrder.arn
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processOrder.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_process_order.arn
}


# SNS For Update Stock
resource "aws_sns_topic" "sns_update_stock" {
  name = "sns_update_stock"
}

data "aws_sns_topic" "sns_update_stock" {
  name = aws_sns_topic.sns_update_stock.name
}

resource "aws_sns_topic_policy" "sns_update_stock_policy" {
  arn = aws_sns_topic.sns_update_stock.arn

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "SNS:Publish",
        "SNS:Subscribe",
        "SNS:Receive"
      ],
      "Resource": "${aws_sns_topic.sns_update_stock.arn}"
    }
  ]
}
EOF
}


resource "aws_sns_topic_subscription" "update_stock_subscription" {
  topic_arn = aws_sns_topic.sns_update_stock.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.updateStock.arn
}

resource "aws_lambda_permission" "with_sns_update_stock" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updateStock.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_update_stock.arn
}
