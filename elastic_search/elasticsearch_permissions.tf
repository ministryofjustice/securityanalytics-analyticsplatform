data "aws_ssm_parameter" "sec_an_user" {
  name = "/${var.app_name}/${terraform.workspace}/users/sec-an/name"
}

data "aws_iam_role" "sec_an_user" {
  name = "${data.aws_ssm_parameter.sec_an_user.value}"
}

resource "aws_iam_role_policy_attachment" "es_user" {
  role       = "${data.aws_iam_role.sec_an_user.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonESCognitoAccess"
}

data "aws_iam_policy_document" "kibana_permissions" {
  statement {
    effect    = "Allow"
    actions   = ["es:ESHttp*"]
    resources = ["${aws_elasticsearch_domain.es.arn}/*"]
  }
}

resource "aws_iam_policy" "kibana_permissions" {
  name   = "${terraform.workspace}-${var.app_name}-kibana-permissions"
  policy = "${data.aws_iam_policy_document.kibana_permissions.json}"
}

resource "aws_iam_role_policy_attachment" "kibana_permissions" {
  role       = "${data.aws_iam_role.sec_an_user.name}"
  policy_arn = "${aws_iam_policy.kibana_permissions.arn}"
}
