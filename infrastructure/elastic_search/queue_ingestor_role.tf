data "aws_iam_policy_document" "queue_ingestor_trust" {
  statement {
    effect = "Allow"

    principals {
      identifiers = [
        "lambda.amazonaws.com",
      ]

      type = "Service"
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "queue_ingestor" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
    ]

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
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/${var.app_name}/${terraform.workspace}/*",
      "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/${var.app_name}/${var.ssm_source_stage}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "es:ESHttp*",
    ]

    resources = [
      "${aws_elasticsearch_domain.es.id}/*",
    ]
  }
}

resource "aws_iam_role" "queue_ingestor" {
  name               = "${terraform.workspace}-${var.app_name}-analytics-elastic-ingestor"
  assume_role_policy = data.aws_iam_policy_document.queue_ingestor_trust.json
}

resource "aws_iam_policy" "queue_ingestor" {
  name   = "${terraform.workspace}-${var.app_name}-analytics-elastic-ingestor"
  policy = data.aws_iam_policy_document.queue_ingestor.json
}

resource "aws_iam_role_policy_attachment" "queue_ingestor" {
  policy_arn = aws_iam_policy.queue_ingestor.arn
  role       = aws_iam_role.queue_ingestor.name
}

