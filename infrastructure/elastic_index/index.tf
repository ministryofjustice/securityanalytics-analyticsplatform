data "local_file" "index_definition" {
  filename = var.index_file
}

data "external" "current_index" {
  count = length(local.flavours)

  program = [
    "python",
    "${path.module}/get-current-write-index.py",
    var.aws_region,
    var.app_name,
    var.task_name,
    "${var.index_name}${local.flavours[count.index]}",
    var.es_domain
  ]
}

locals {
  # If flavours are explicitly provided use them, otherwise, if snapshot and history are enabled those
  # two flavours are used, otherwise no flavours are used
  flavours = var.flavours == null ? (var.snapshot_and_history ? ["_history", "_snapshot"] : [""]) : var.flavours
}

resource "null_resource" "setup_new_index" {
  # This count stops us from re-indexing dev, when looking at integration tests
  count = var.ssm_source_stage == terraform.workspace ? length(local.flavours) : 0

  triggers = {
    index_hash  = md5(data.local_file.index_definition.content)
    script_hash = filemd5("${path.module}/write-new-index.py")
    # Since terraform has no way to query the actual state of these resources, it will not re-create them if they have been deleted. This (although making the build noisy), will ensure that they are always created.
    allways = timestamp()
  }

  provisioner "local-exec" {
    # Doesn't just write the new one, it also updates the aliases and starts re-indexing
    command = "python ${path.module}/write-new-index.py ${var.aws_region} ${var.app_name} ${var.task_name} ${var.index_name}${local.flavours[count.index]} ${self.triggers.index_hash} ${data.local_file.index_definition.filename} ${var.es_domain} ${data.external.current_index.*.result.index[count.index]}"
  }
}

