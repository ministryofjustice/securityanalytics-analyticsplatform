resource "aws_lambda_permission" "dynamo_invoke" {
  statement_id  = "AllowExecutionFromDynamoDB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sync_info.function_name
  principal     = "dynamodb.amazonaws.com"
  source_arn    = var.dynamodb_stream_arn
}

resource "aws_lambda_event_source_mapping" "table_sync_trigger" {
  depends_on = [aws_lambda_permission.dynamo_invoke]
  event_source_arn = var.dynamodb_stream_arn
  function_name = aws_lambda_function.sync_info.function_name
  starting_position = "LATEST"
}

module "sync_table_dlq" {
  source = "github.com/ministryofjustice/securityanalytics-sharedcode//infrastructure/dead_letter_recorder"
  # source = "../../../securityanalytics-sharedcode/infrastructure/dead_letter_recorder"
  aws_region = var.aws_region
  app_name = var.app_name
  account_id = var.account_id
  ssm_source_stage = var.ssm_source_stage
  use_xray = var.use_xray
  recorder_name = "sync-${var.syncer_name}-DLQ"
  s3_bucket = data.aws_ssm_parameter.dead_letter_bucket_name.value
  s3_bucket_arn = data.aws_ssm_parameter.dead_letter_bucket_arn.value
  s3_key_prefix = "analytics_platform/sync-${var.syncer_name}"
  source_arn = aws_lambda_function.sync_info.arn
}

resource "aws_lambda_function" "sync_info" {
  function_name    = "${terraform.workspace}-${var.app_name}-sync-${var.syncer_name}"
  handler          = var.set_column_to_diff == null ? "dynamo_elastic_sync.dynamo_elastic_sync.forward_record" : "dynamo_elastic_sync.diffing_sync.forward_record"
  role             = aws_iam_role.table_syncer.arn
  runtime          = "python3.7"
  filename         = "${path.module}/empty.zip"
  source_code_hash = filebase64sha256("${path.module}/empty.zip")

  layers = [
    data.aws_ssm_parameter.utils_layer.value,
    data.aws_ssm_parameter.sync_layer.value,
  ]

  tracing_config {
    mode = var.use_xray ? "Active" : "PassThrough"
  }

  # Fairly big batches are sent, never normally takes more than 10s, 6x safety factor
  timeout = 60

  environment {
    variables = {
      REGION   = var.aws_region
      STAGE    = terraform.workspace
      APP_NAME = var.app_name
      USE_XRAY = var.use_xray
      # Our convention is snake case for indexes, but kebab case for names, so convert here
      ES_INDEX_NAME = replace(var.syncer_name, "-", "_")
      # Since dynamo streams are called
      DLQ = module.sync_table_dlq.url
      SET_COLUMN_TO_DIFF = var.set_column_to_diff == null ? "" : var.set_column_to_diff
      NON_TEMPORAL_KEY_FIELD = var.non_temporal_key_field != null ? var.non_temporal_key_field : ""
      TEMPORAL_KEY_FIELD = var.temporal_key_field != null ? var. temporal_key_field : ""
    }
  }

  tags = {
    workspace = terraform.workspace
    app_name  = var.app_name
  }
}