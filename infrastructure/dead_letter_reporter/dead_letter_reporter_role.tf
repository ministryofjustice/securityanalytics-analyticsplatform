resource "aws_iam_role" "reporter_role" {
  name               = "${terraform.workspace}-${var.app_name}-dead-letter-reporter"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

data "aws_iam_policy_document" "reporter_policy" {
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
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = [
      data.aws_ssm_parameter.dead_letter_bucket_arn.value,
      "${data.aws_ssm_parameter.dead_letter_bucket_arn.value}/*",
    ]
  }

  # So the task trigger can find the locations of e.g. queues
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/${var.app_name}/${terraform.workspace}/*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [var.ingest_queue]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
    ]

    # TODO reduce this scope
    resources = ["*"]
  }
}

resource "aws_iam_policy" "reporter_policy" {
  name   = "${terraform.workspace}-${var.app_name}-dead-letter-reporter"
  policy = data.aws_iam_policy_document.reporter_policy.json
}

resource "aws_iam_role_policy_attachment" "reporter_policy" {
  role       = aws_iam_role.reporter_role.name
  policy_arn = aws_iam_policy.reporter_policy.arn
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
