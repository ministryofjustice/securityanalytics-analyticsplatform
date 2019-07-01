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
  type        = string
  description = "Whether to instrument lambdas"
}

variable "dynamodb_stream_arn" {
  type = string
}

variable "set_column_to_diff" {
  type        = string
  default     = null
  description = "If set then each record sent to elastic which will have an additiional two columns for items added and removed"
}

variable "syncer_name" {
  type = string
}

variable "non_temporal_key_field" {
  type        = string
  default     = null
  description = "If specified, this will be used to specify which field in the DB will be used as the non temporal key, should be set to the hash key of the table"
}

variable "temporal_key_field" {
  type        = string
  default     = null
  description = "If specified, this will be used to specify which field in the DB will be used as the temporal key, should be set to the range key of the table. This should not be set if the non temporal key is not set."
}