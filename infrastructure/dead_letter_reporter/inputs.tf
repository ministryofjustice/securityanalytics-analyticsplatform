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
  type        = bool
  description = "Whether to instrument lambdas"
}

variable "ingest_queue" {
  type = string
}

variable "es_domain" {
  type = string
}
