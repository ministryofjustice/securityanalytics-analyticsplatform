resource "aws_sqs_queue" "injestion_queue" {
  name = "${terraform.workspace}-${var.app_name}-es-injestion-queue"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}
