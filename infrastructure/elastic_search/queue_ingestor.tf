locals {
  analytics_zip = "../.generated/sec-an-analytics.zip"
}

data "external" "analytics_zip" {
  program = [
    "python",
    "../shared_code/python/package_lambda.py",
    "${local.analytics_zip}",
    "${path.module}/packaging.config.json",
    "../Pipfile.lock",
  ]
}

resource "aws_lambda_permission" "sqs_invoke" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.queue_ingestor.function_name}"
  principal     = "sqs.amazonaws.com"
  source_arn    = "${aws_sqs_queue.ingestion_queue.arn}"
}

resource "aws_lambda_event_source_mapping" "ingestor_queue_trigger" {
  depends_on       = ["aws_lambda_permission.sqs_invoke", "aws_iam_role_policy_attachment.queue_ingestor"]
  event_source_arn = "${aws_sqs_queue.ingestion_queue.arn}"
  function_name    = "${aws_lambda_function.queue_ingestor.arn}"
  enabled          = true
  batch_size       = 1
}

resource "aws_lambda_function" "queue_ingestor" {
  function_name    = "${terraform.workspace}-${var.app_name}-analytics-ingestor"
  handler          = "queue_ingestor.queue_ingestor.ingest"
  role             = "${aws_iam_role.queue_ingestor.arn}"
  runtime          = "python3.7"
  filename         = "${local.analytics_zip}"
  source_code_hash = "${data.external.analytics_zip.result.hash}"

  layers = [
    "${data.aws_ssm_parameter.utils_layer.value}",
  ]

  environment {
    variables = {
      REGION    = "${var.aws_region}"
      STAGE     = "${terraform.workspace}"
      APP_NAME  = "${var.app_name}"
      TASK_NAME = "analytics"
    }
  }

  tags = {
    workspace = "${terraform.workspace}"
    app_name  = "${var.app_name}"
  }
}
