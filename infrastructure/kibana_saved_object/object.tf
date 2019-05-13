data "template_file" "object_definition" {
  template = "${file(var.object_template)}"
  vars ="${merge(map("object_title",var.object_title), var.object_substitutions)}"
}

data "external" "current_object" {
  program = [
    "python",
    "${path.module}/get_current_object.py",
    "${var.aws_region}",
    "${var.app_name}",
    "${urlencode(var.object_title)}",
    "${var.object_type}",
    "${data.aws_ssm_parameter.es_domain.value}",
  ]
}

locals {
  base_name = "${basename(var.object_template)}"
}

resource "local_file" "object_definition" {
  filename = "../.generated/${local.base_name}"
  content = "${data.template_file.object_definition.rendered}"
}

# We always override the dashboard with the version we have, everytime we deploy, this is a quick operation thankfully
resource "null_resource" "update_object_definition" {
  # This count stops us from re-indexing dev, when looking at integration tests
  count = "${var.ssm_source_stage == terraform.workspace ? 1 : 0}"

  triggers {
    allways  = "${md5(local_file.object_definition.content)}"
  }

  provisioner "local-exec" {
    # Doesn't just write the new one, it also updates the aliases and starts re-indexing
    command = "python ${path.module}/update_object.py ${var.aws_region} ${var.app_name} ${local_file.object_definition.filename} ${var.object_type} ${data.external.current_object.result.existing_ids} ${data.aws_ssm_parameter.es_domain.value}"
  }
}
