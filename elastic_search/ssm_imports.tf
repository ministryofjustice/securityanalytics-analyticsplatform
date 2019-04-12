data "aws_ssm_parameter" "cidr_block" {
  name = "/${var.app_name}/${terraform.workspace}/vpc/cidr_block"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.app_name}/${terraform.workspace}/vpc/id"
}

data "aws_ssm_parameter" "user_pool" {
  name = "/${var.app_name}/${terraform.workspace}/cognito/pool/user"
}

data "aws_ssm_parameter" "identity_pool" {
  name = "/${var.app_name}/${terraform.workspace}/cognito/pool/identity"
}

data "aws_ssm_parameter" "cognito_user_arn" {
  name = "/${var.app_name}/${terraform.workspace}/users/sec-an/arn"
}
