resource "aws_ssm_parameter" "elastic_ingestion_queue_arn" {
  name        = "/${var.app_name}/${terraform.workspace}/analytics/kibana/dead_letter_index_pattern/id"
  description = "The arn of the ingestion queue"
  type        = "String"
  value       = module.dead_letter_index_pattern.object_id
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

