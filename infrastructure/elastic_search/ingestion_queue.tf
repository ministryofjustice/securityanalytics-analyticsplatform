data "aws_iam_policy_document" "notify_topic_policy" {
  statement {
    actions = [
      "sqs:SendMessage",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:aws:*:${var.aws_region}:${var.account_id}:*",
      ]
    }

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [
      aws_sqs_queue.ingestion_queue.arn,
    ]
  }
}

resource "aws_sqs_queue" "ingestion_queue" {
  name = "${terraform.workspace}-${var.app_name}-es-ingestion-queue"

  visibility_timeout_seconds = var.analytics_ingestion_timeout + 1

  # N.B. We do not add a dead letter queue to this queue, because we would end up with a loop
  # where the dead letter is put on this queue

  # TODO add queue encryption

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = aws_sqs_queue.ingestion_queue.id
  policy    = data.aws_iam_policy_document.notify_topic_policy.json
}

