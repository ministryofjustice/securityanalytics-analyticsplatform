data "aws_ssm_parameter" "cidr_block" {
  name = "/${var.app_name}/${ssm_source_stage}/vpc/cidr_block"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.app_name}/${ssm_source_stage}/vpc/id"
}

data "aws_ssm_parameter" "user_pool" {
  name = "/${var.app_name}/${ssm_source_stage}/cognito/pool/user"
}

data "aws_ssm_parameter" "identity_pool" {
  name = "/${var.app_name}/${ssm_source_stage}/cognito/pool/identity"
}

data "aws_ssm_parameter" "cognito_user_arn" {
  name = "/${var.app_name}/${ssm_source_stage}/users/sec-an/arn"
}
