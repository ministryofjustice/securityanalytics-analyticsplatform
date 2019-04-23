resource "aws_security_group" "es" {
  name   = "${terraform.workspace}-${var.app_name}-es"
  vpc_id = "${data.aws_ssm_parameter.vpc_id.value}"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${data.aws_ssm_parameter.cidr_block.value}",
    ]
  }

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}

locals {
  // Have to use only 2 AZs because of terraform issue  // https://github.com/terraform-providers/terraform-provider-aws/issues/7504

  subnets_list = ["${data.aws_ssm_parameter.instance_subnets.value}"]

  # elastic_subnets = "${split(",", 
  #                     (data.aws_ssm_parameter.num_azs.value == 1 ?  
  #                       join(",", list(local.subnets_list[0])) : 
  #                       join(",", list(local.subnets_list[0], local.subnets_list[1]))
  #                     )
  #                 )}"

  elastic_subnets        = "${local.subnets_list}"
  elastic_instance_count = "${data.aws_ssm_parameter.num_azs.value == 1 ?  1 : 2 }"
}

output "num_azs" {
  value = "${data.aws_ssm_parameter.num_azs.value}"
}

data "aws_caller_identity" "account" {}

resource "aws_elasticsearch_domain" "es" {
  domain_name = "d-${terraform.workspace}-${var.app_name}-es"

  elasticsearch_version = "6.3"

  access_policies = <<CONFIG
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "es:*",
      "Principal":"*",
      "Resource": "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.account.account_id}:domain/${terraform.workspace}-${var.app_name}-es/*"
    }
  ]
}
  CONFIG

  cluster_config {
    instance_type          = "t2.small.elasticsearch"
    zone_awareness_enabled = "${local.elastic_instance_count > 1}"
    instance_count         = "${local.elastic_instance_count}"
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  # TODO: make this work correctly with VPC
  # vpc_options {
  #   subnet_ids         = ["${local.elastic_subnets}"]
  #   security_group_ids = ["${aws_security_group.es.id}"]
  # }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }
  cognito_options {
    enabled          = true
    user_pool_id     = "${data.aws_ssm_parameter.user_pool.value}"
    identity_pool_id = "${data.aws_ssm_parameter.identity_pool.value}"
    role_arn         = "${data.aws_iam_role.sec_an_user.arn}"
  }
  tags {
    Domain             = "SecurityData"
    app_name           = "${var.app_name}"
    workspace          = "${terraform.workspace}"
    confirm_attachment = "${aws_iam_role_policy_attachment.es_user.policy_arn}"
  }
}
