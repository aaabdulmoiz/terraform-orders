# POST Create Order API
resource "aws_apigatewayv2_integration" "lambda_createOrder" {
  api_id = aws_apigatewayv2_api.main.id

  integration_uri    = aws_lambda_function.createOrder.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}


resource "aws_apigatewayv2_route" "post_createOrder" {
  api_id = aws_apigatewayv2_api.main.id

  route_key = "POST /order"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_createOrder.id}"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.createOrder.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# GET API Integration

resource "aws_apigatewayv2_integration" "lambda_getOrder" {
  api_id = aws_apigatewayv2_api.main.id

  integration_uri  = aws_lambda_function.getOrder.invoke_arn
  integration_type = "AWS_PROXY"  # Use AWS_PROXY for Lambda integration
}

resource "aws_apigatewayv2_route" "get_getOrder" {
  api_id = aws_apigatewayv2_api.main.id

  route_key = "GET /order"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_getOrder.id}"
}

resource "aws_lambda_permission" "api_gw_getOrder" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.getOrder.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

output "order_base_url" {
  value = aws_apigatewayv2_stage.dev.invoke_url
}
