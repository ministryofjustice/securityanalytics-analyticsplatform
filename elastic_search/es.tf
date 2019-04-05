resource "aws_security_group" "es" {
  name   = "${var.app_name}-es-${terraform.workspace}"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      "${var.cidr_block}",
    ]
  }

  tags {
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}

resource "aws_elasticsearch_domain" "es" {
  //TODO: need cognito user pool
  //depends_on  = ["aws_iam_role_policy_attachment.es_user"]
  domain_name = "${var.app_name}-es-${terraform.workspace}"

  elasticsearch_version = "6.3"

  cluster_config {
    instance_type = "t2.small.elasticsearch"

    //    zone_awareness_enabled = true
    //    // Have to use only 2 AZs because of terraform issue
    //    // https://github.com/terraform-providers/terraform-provider-aws/issues/7504
    //    instance_count = 2
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  //  vpc_options {
  //    // Have to use only 2 AZs because of terraform issue
  //    // https://github.com/terraform-providers/terraform-provider-aws/issues/7504
  //    subnet_ids = [ "${module.vpc.instance_subnets[0]}", "${module.vpc.instance_subnets[1]}" ]
  //    security_group_ids = ["${aws_security_group.es.id}"]
  //  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }
  cognito_options {
    enabled = true

    /*
          user_pool_id     = "${aws_cognito_user_pool.kibana_pool.id}"
          identity_pool_id = "${aws_cognito_identity_pool.kibana_pool.id}"          
          role_arn = "${aws_iam_role.es_user.arn}"
        */
    //TODO: read this from cognito user pool once this is done
    user_pool_id = "dummy_user_pool_id"

    identity_pool_id = "dummy_identity_pool_id"
    role_arn         = "dummy_role_arn"
  }
  tags {
    Domain    = "SecurityData"
    app_name  = "${var.app_name}"
    workspace = "${terraform.workspace}"
  }
}
