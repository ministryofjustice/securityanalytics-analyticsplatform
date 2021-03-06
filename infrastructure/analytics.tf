#############################################
# Backend setup
#############################################

terraform {
  backend "s3" {
    # This is configured using the -backend-config parameter with 'terraform init'
    bucket         = ""
    dynamodb_table = "sec-an-terraform-locks"
    key            = "analytics/terraform.tfstate"
    region         = "eu-west-2" # london
  }
}

#############################################
# Variables used across the whole application
#############################################

variable "aws_region" {
  default = "eu-west-2" # london
}

# Set this variable with your app.auto.tfvars file or enter it manually when prompted
variable "app_name" {
}

variable "ssm_source_stage" {
  default = "DEFAULT"
}

variable "account_id" {
}

variable "use_xray" {
  type        = string
  description = "Whether to instrument lambdas"
  default     = false
}

provider "aws" {
  version = "~> 2.13"
  region  = var.aws_region

  # N.B. To support all authentication use cases, we expect the local environment variables to provide auth details.
  allowed_account_ids = [var.account_id]
}

#############################################
# Resources
#############################################

locals {
  # When a build is done as a user locally, or when building a stage e.g. dev/qa/prod we use
  # the workspace name e.g. progers or dev
  # When the circle ci build is run we override the var.ssm_source_stage to explicitly tell it
  # to use the resources in dev
  ssm_source_stage = var.ssm_source_stage == "DEFAULT" ? terraform.workspace : var.ssm_source_stage
}

module "elastic_search" {
  source           = "./elastic_search"
  app_name         = var.app_name
  aws_region       = var.aws_region
  ssm_source_stage = local.ssm_source_stage
  account_id       = var.account_id
  use_xray         = var.use_xray
}

module "dead_letter_reporter" {
  source           = "./dead_letter_reporter"
  app_name         = var.app_name
  aws_region       = var.aws_region
  ssm_source_stage = local.ssm_source_stage
  account_id       = var.account_id
  use_xray         = var.use_xray
  ingest_queue     = module.elastic_search.ingest_queue
  es_domain        = module.elastic_search.es_domain
}

module "dynamo_elastic_sync" {
  source           = "./dynamo_elastic_sync_layer"
  app_name         = var.app_name
  aws_region       = var.aws_region
  ssm_source_stage = local.ssm_source_stage
  account_id       = var.account_id
}
