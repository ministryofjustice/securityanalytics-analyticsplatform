variable "aws_region" {
  type = string
}

variable "app_name" {
  type = string
}

variable "task_name" {
  type = string
}

variable "index_name" {
  type = string
}

variable "ssm_source_stage" {
  type        = string
  description = "When deploying infrastructure for integration tests the source of ssm parameters for e.g. the congnito pool need to come from dev, not from the stage with the same name."
}

variable "index_file" {
  type = string
}

variable "es_domain" {
  type = string
}

variable "snapshot_and_history" {
  type        = bool
  description = "Whether this particular source of data will have separate history and snapshot indexes"
  default     = true
}

variable "flavours" {
  type        = list(string)
  description = "Override e.g. snapshot and history with your own set of flavours"
  default     = null
}