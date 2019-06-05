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
  default = true
}

