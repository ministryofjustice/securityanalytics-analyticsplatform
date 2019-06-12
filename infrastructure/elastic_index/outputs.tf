# N.B. until terraform 0.12 we need this workaround
# https://github.com/hashicorp/terraform/issues/12453#issuecomment-311611817
locals {
  index_hashes      = null_resource.setup_new_index.*.triggers.index_hash
  no_index_response = ["noIndex", "noIndex"]
  integration_env   = var.ssm_source_stage == terraform.workspace

  index_ids = slice(
    concat(local.index_hashes, local.no_index_response),
    local.integration_env ? 0 : length(local.index_hashes),
    local.integration_env ? length(local.index_hashes) : length(local.index_hashes) + length(local.no_index_response)
  )
}

output "index_id" {
  value = var.snapshot_and_history ?
    local.index_ids[index(local.flavours, "_snapshot")] :
    local.index_ids[0]
}

output "history_index_id" {
  value = var.snapshot_and_history ?
    local.index_ids[index(local.flavours, "_history")] :
    local.index_ids[0]
}

output "snapshot_index_id" {
  value = var.snapshot_and_history ?
    local.index_ids[index(local.flavours, "snapshot")] :
    local.index_ids[0]
}

