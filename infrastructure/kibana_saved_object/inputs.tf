variable "aws_region" {
  type = "string"
}

variable "app_name" {
  type = "string"
}

variable "task_name" {
  type = "string"
}

variable "ssm_source_stage" {
  type        = "string"
  description = "When deploying infrastructure for integration tests the source of ssm parameters for e.g. the congnito pool need to come from dev, not from the stage with the same name."
}

variable "object_title" {
  type = "string"
}

variable "object_template" {
  type = "string"
}

variable "object_type" {
  type = "string"
}

variable "object_substitutions" {
  type = "map"
}