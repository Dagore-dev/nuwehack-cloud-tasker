provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    events         = "http://localhost:4566"
    iam            = "http://localhost:4566"
    sts            = "http://localhost:4566"
    s3             = "http://localhost:4566"
  }
}

resource "aws_dynamodb_table" "tasks" {
  name           = "tasks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "task_id"
  attribute {
    name = "task_id"
    type = "S"
  }
}

resource "aws_lambda_function" "create_scheduled_task" {
  filename      = "${path.module}/Infraestructure/lambda/createScheduledTask.py"
  function_name = "createScheduledTask"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "createScheduledTask.handler"
  runtime       = "python3.8"
}

resource "aws_lambda_function" "list_scheduled_task" {
  filename      = "${path.module}/Infraestructure/lambda/listScheduledTask.py"
  function_name = "listScheduledTask"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "listScheduledTask.handler"
  runtime       = "python3.8"
}

resource "aws_apigatewayv2_api" "task_api" {
  name          = "TaskAPI"
  protocol_type = "HTTP"
  target        = aws_lambda_function.create_scheduled_task.invoke_arn
}

resource "aws_apigatewayv2_integration" "create_task_integration" {
  api_id            = aws_apigatewayv2_api.task_api.id
  integration_type  = "AWS_PROXY"
  integration_uri   = aws_lambda_function.create_scheduled_task.invoke_arn
}

resource "aws_apigatewayv2_route" "create_task_route" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "POST /createtask"
  target    = "integrations/${aws_apigatewayv2_integration.create_task_integration.id}"
}

resource "aws_apigatewayv2_integration" "list_task_integration" {
  api_id            = aws_apigatewayv2_api.task_api.id
  integration_type  = "AWS_PROXY"
  integration_uri   = aws_lambda_function.list_scheduled_task.invoke_arn
}

resource "aws_apigatewayv2_route" "list_task_route" {
  api_id    = aws_apigatewayv2_api.task_api.id
  route_key = "GET /listtask"
  target    = "integrations/${aws_apigatewayv2_integration.list_task_integration.id}"
}

resource "aws_s3_bucket" "taskstorage" {
  bucket = "taskstorage"
  acl    = "private"
}

resource "aws_cloudwatch_event_rule" "execute_task_rule" {
  name                = "ExecuteTaskRule"
  description         = "Rule to trigger executeScheduledTask Lambda every minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "execute_task_target" {
  rule       = aws_cloudwatch_event_rule.execute_task_rule.name
  target_id  = "executeTaskTarget"
  arn        = aws_lambda_function.execute_scheduled_task.arn
}

resource "aws_lambda_permission" "allow_eventbridge_execution" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.execute_scheduled_task.arn
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.execute_task_rule.arn
}
