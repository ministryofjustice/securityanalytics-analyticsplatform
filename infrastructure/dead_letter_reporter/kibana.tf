module "dead_letter_index" {
  source = "../elastic_index"
  app_name = var.app_name
  aws_region       = var.aws_region
  ssm_source_stage = var.ssm_source_stage
  index_file       = "${path.module}/dead_letter.index.json"
  index_name       = "data"
  task_name        = "dead_letter"
}

module "dead_letter_index_history" {
  source = "../kibana_saved_object"
  app_name = var.app_name
  aws_region           = var.aws_region
  ssm_source_stage     = var.ssm_source_stage
  task_name            = "dead_letter"
  object_template      = "${path.module}/dead_letter.pattern.json"
  object_substitutions = {}

  object_type  = "index-pattern"
  object_title = "dead_letter:data_history:read*"
}

module "dead_letter_index_snapshot" {
  source = "../kibana_saved_object"
  app_name = var.app_name
  aws_region           = var.aws_region
  ssm_source_stage     = var.ssm_source_stage
  task_name            = "dead_letter"
  object_template      = "${path.module}/dead_letter.pattern.json"
  object_substitutions = {}

  object_type  = "index-pattern"
  object_title = "dead_letter:data_snapshot:read*"
}

module "dead_letter_visualisation" {
  source = "../kibana_saved_object"
  app_name = var.app_name
  aws_region       = var.aws_region
  ssm_source_stage = var.ssm_source_stage
  task_name        = "dead_letter"
  object_template  = "${path.module}/dead_letter.vis.json"

  object_substitutions = {
    index = module.dead_letter_index_history.object_id
  }

  object_type  = "visualization"
  object_title = "Dead Letters"
}
