# This reporter consists of an s3 put object trigger which will send a message to the
# queue feeding elastic search with details of the new dead letter so that we can report
# on dead letters in kibana

resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dlq_reporter.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_ssm_parameter.dead_letter_bucket_arn.value
}

resource "aws_s3_bucket_notification" "reporter_trigger" {
  depends_on = [aws_lambda_permission.s3_invoke]
  bucket     = data.aws_ssm_parameter.dead_letter_bucket_name.value

  lambda_function {
    lambda_function_arn = aws_lambda_function.dlq_reporter.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".tar.gz"
  }
}

locals {
  reporter_zip = "../.generated/${var.app_name}_dead_letter_reporter.zip"
}

data "external" "reporter_zip" {
  program = ["python", "../shared_code/python/package_lambda.py", "-x", local.reporter_zip, "${path.module}/packaging.config.json", "../Pipfile.lock"]
}

resource "aws_lambda_function" "dlq_reporter" {
  function_name    = "${terraform.workspace}-${var.app_name}-dead-letter-reporter"
  handler          = "dead_letter_reporter.dead_letter_reporter.report_letters"
  role             = aws_iam_role.reporter_role.arn
  runtime          = "python3.7"
  filename         = local.reporter_zip
  source_code_hash = data.external.reporter_zip.result.hash

  layers = [
    data.aws_ssm_parameter.utils_layer.value
  ]

  tracing_config {
    mode = var.use_xray ? "Active" : "PassThrough"
  }

  environment {
    variables = {
      REGION   = var.aws_region
      STAGE    = terraform.workspace
      APP_NAME = var.app_name
    }
  }

  tags = {
    workspace = terraform.workspace
    app_name  = var.app_name
  }
}

