resource "aws_sqs_queue" "ingestion_queue" {
  name = "${terraform.workspace}-${var.app_name}-es-ingestion-queue"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}
