data "aws_iam_policy_document" "notify_topic_policy" {
  statement {
    actions = [
      "sqs:SendMessage",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        "arn:aws:sns:${var.aws_region}:${var.account_id}:*",
      ]
    }

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [
      "${aws_sqs_queue.ingestion_queue.arn}",
    ]
  }
}

resource "aws_sqs_queue" "ingestion_queue" {
  name = "${terraform.workspace}-${var.app_name}-es-ingestion-queue"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}

resource "aws_sqs_queue_policy" "queue_policy" {
  queue_url = "${aws_sqs_queue.ingestion_queue.id}"
  policy    = "${data.aws_iam_policy_document.notify_topic_policy.json}"
}
