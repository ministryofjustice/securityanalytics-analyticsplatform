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
  // source = "../../../securityanalytics-sharedcode/infrastructure/dead_letter_recorder"
  aws_region = var.aws_region
  app_name = var.app_name
  account_id = var.account_id
  ssm_source_stage = var.ssm_source_stage
  use_xray = var.use_xray
  recorder_name = "sync-${var.syncer_name}-DLQ"
  s3_bucket = data.aws_ssm_parameter.dead_letter_bucket_name.value
  s3_bucket_arn = data.aws_ssm_parameter.dead_letter_bucket_arn.value
  s3_key_prefix = "task_execution/sync-address-info"
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

  dead_letter_config {
    target_arn = module.sync_table_dlq.arn
  }

  tracing_config {
    mode = var.use_xray ? "Active" : "PassThrough"
  }

  environment {
    variables = {
      REGION   = var.aws_region
      STAGE    = terraform.workspace
      APP_NAME = var.app_name
      USE_XRAY = var.use_xray
      ES_INDEX_NAME = "scanning_status"
      SET_COLUMN_TO_DIFF = var.set_column_to_diff == null ? "" : var.set_column_to_diff
    }
  }

  tags = {
    workspace = terraform.workspace
    app_name  = var.app_name
  }
}

data "aws_iam_policy_document" "table_syncer_perms" {
  # So the task trigger can find the locations of e.g. queues
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
    ]

    # TODO make a better bound here
    resources = [
      "*",
    ]
  }

  # To enable XRAY trace
  statement {
    effect = "Allow"

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries"
    ]

    # TODO make a better bound here
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    # TODO reduce this scope
    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "sqs:Send*",
    ]

    resources = [
      data.aws_ssm_parameter.elastic_ingestion_queue_arn.value,
      module.sync_table_dlq.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams"
    ]

    resources = [
      var.dynamodb_stream_arn
    ]
  }
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "table_syncer" {
  name               = "${terraform.workspace}-${var.app_name}-${var.syncer_name}-syncer"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_iam_policy" "table_syncer_perms" {
  name   = "${terraform.workspace}-${var.app_name}-${var.syncer_name}-syncer"
  policy = data.aws_iam_policy_document.table_syncer_perms.json
}

resource "aws_iam_role_policy_attachment" "table_syncer_perms" {
  role       = aws_iam_role.table_syncer.name
  policy_arn = aws_iam_policy.table_syncer_perms.id
}
