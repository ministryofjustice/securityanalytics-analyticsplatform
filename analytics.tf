#############################################
# Backend setup
#############################################

terraform {
  backend "s3" {
    bucket         = "sec-an-terraform-state"
    dynamodb_table = "sec-an-terraform-locks"
    key            = "analytics/terraform.tfstate"
    region         = "eu-west-2"                   # london
    profile        = "sec-an"
  }
}

#############################################
# Variables used across the whole application
#############################################

variable "aws_region" {
  default = "eu-west-2" # london
}

variable "app_name" {
  default = "sec-an"
}

variable "account_id" {}

provider "aws" {
  region              = "${var.aws_region}"
  profile             = "${var.app_name}"
  allowed_account_ids = ["${var.account_id}"]
}

#############################################
# Resources
#############################################
data "aws_ssm_parameter" "cidr_block" {
  name = "/${var.app_name}/${terraform.workspace}/vpc/cidr_block"
}

data "aws_ssm_parameter" "id" {
  name = "/${var.app_name}/${terraform.workspace}/vpc/id"
}

module "elastic_search" {
  source     = "elastic_search"
  app_name   = "${var.app_name}"
  cidr_block = "${data.aws_ssm_parameter.cidr_block.value}"
  vpc_id     = "${data.aws_ssm_parameter.id.value}"
}
