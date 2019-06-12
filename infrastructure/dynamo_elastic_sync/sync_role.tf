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