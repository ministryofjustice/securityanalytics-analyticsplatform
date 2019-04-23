resource "aws_ssm_parameter" "elastic_injestion_queue_arn" {
  name        = "/${var.app_name}/${terraform.workspace}/analytics/elastic/injest_queue/arn"
  description = "The arn of the injestion queue"
  type        = "String"
  value       = "${aws_sqs_queue.injestion-queue.arn}"
  overwrite   = "true"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}

resource "aws_ssm_parameter" "elastic_injestion_queue_id" {
  name        = "/${var.app_name}/${terraform.workspace}/analytics/elastic/injest_queue/id"
  description = "The id (url) of the injestion queue"
  type        = "String"
  value       = "${aws_sqs_queue.injestion-queue.id}"
  overwrite   = "true"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}