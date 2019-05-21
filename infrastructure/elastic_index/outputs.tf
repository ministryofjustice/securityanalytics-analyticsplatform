output "history_index_id" {
  value = "${var.ssm_source_stage == terraform.workspace ?
  null_resource.setup_new_index.*.triggers.index_hash[index(local.flavours, "history")] : "NoIndex"}"
}

output "snapshot_index_id" {
  value = "${var.ssm_source_stage == terraform.workspace ? null_resource.setup_new_index.*.triggers.index_hash[index(local.flavours, "snapshot")]: "NoIndex"}"
}
