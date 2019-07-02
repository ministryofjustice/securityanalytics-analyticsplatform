resource "aws_ssm_parameter" "elastic_ingestion_queue_arn" {
  name        = "/${var.app_name}/${terraform.workspace}/analytics/kibana/dead_letter_index_pattern/id"
  description = "The object id of the viusalisation of dead letter queues"
  type        = "String"
  value       = module.dead_letter_visualisation.object_id
  overwrite   = "true"

  tags = {
    app_name  = var.app_name
    workspace = terraform.workspace
  }
}

