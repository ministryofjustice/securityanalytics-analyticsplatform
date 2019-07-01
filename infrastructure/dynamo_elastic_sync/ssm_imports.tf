data "aws_ssm_parameter" "utils_layer" {
  name = "/${var.app_name}/${var.ssm_source_stage}/lambda/layers/utils/arn"
}

data "aws_ssm_parameter" "sync_layer" {
  name = "/${var.app_name}/${var.ssm_source_stage}/lambda/layers/dynamo_elastic_sync/arn"
}

data "aws_ssm_parameter" "dead_letter_bucket_name" {
  name = "/${var.app_name}/${var.ssm_source_stage}/s3/dead_letters/name"
}

data "aws_ssm_parameter" "dead_letter_bucket_arn" {
  name = "/${var.app_name}/${var.ssm_source_stage}/s3/dead_letters/arn"
}

data "aws_ssm_parameter" "elastic_ingestion_queue_arn" {
  name = "/${var.app_name}/${var.ssm_source_stage}/analytics/elastic/ingest_queue/arn"
}