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

  // It is sometimes useful for the developers of the project to use a local version of the task
  // execution project. This enables them to develop the task execution project and the nmap scanner
  // (or other future tasks), at the same time, without requiring the task execution changes to be
  // pushed to master. Unfortunately you can not interpolate variables to generate source locations, so
  // devs will have to comment in/out this line as and when they need
  //  source = "../../../securityanalytics-analyticsplatform/infrastructure/kibana_saved_object"
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
