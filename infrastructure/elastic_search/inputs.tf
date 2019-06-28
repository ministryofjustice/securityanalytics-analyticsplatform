variable "app_name" {
  type = string
}

variable "aws_region" {
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

variable "analytics_ingestion_timeout" {
  type = number
  # Really should never need that long, but 3 seconds is too short now we have doc collections
  default = 2 * 60
}

