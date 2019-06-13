variable "aws_region" {
  type = string
}

variable "app_name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "ssm_source_stage" {
  type = string
}

variable "use_xray" {
  type = string
  description = "Whether to instrument lambdas"
}

variable "dynamodb_stream_arn" {
  type = string
}

variable "set_column_to_diff" {
  type = string
  default = null
  description = "If set then each record sent to elastic which will have an additiional two columns for items added and removed"
}

variable "syncer_name" {
  type = string
}