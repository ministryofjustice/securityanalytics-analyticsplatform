resource "aws_ssm_parameter" "elastic_ingestion_queue_arn" {
  name        = "/${var.app_name}/${terraform.workspace}/analytics/elastic/ingest_queue/arn"
  description = "The arn of the ingestion queue"
  type        = "String"
  value       = "${aws_sqs_queue.ingestion_queue.arn}"
  overwrite   = "true"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}

resource "aws_ssm_parameter" "elastic_ingestion_queue_id" {
  name        = "/${var.app_name}/${terraform.workspace}/analytics/elastic/ingest_queue/id"
  description = "The id (url) of the ingestion queue"
  type        = "String"
  value       = "${aws_sqs_queue.ingestion_queue.id}"
  overwrite   = "true"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}

resource "aws_ssm_parameter" "elasticsearch_endpoint" {
  name        = "/${var.app_name}/${terraform.workspace}/analytics/elastic/es_endpoint/url"
  description = "The url of the elasticsearch endpoint"
  type        = "String"
  value       = "${aws_elasticsearch_domain.es.endpoint}"
  overwrite   = "true"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}

resource "aws_ssm_parameter" "elasticsearch_arn" {
  name        = "/${var.app_name}/${terraform.workspace}/analytics/elastic/es_endpoint/arn"
  description = "The arn of the elasticsearch endpoint"
  type        = "String"
  value       = "${aws_elasticsearch_domain.es.arn}"
  overwrite   = "true"

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}
