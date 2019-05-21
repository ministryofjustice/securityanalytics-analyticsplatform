output "history_index_id" {
  value = "${var.ssm_source_stage == terraform.workspace ?
  null_resource.setup_new_index.*.triggers.index_hash[0] : "NoIndex"}"
}

output "snapshot_index_id" {
  value = "${var.ssm_source_stage == terraform.workspace ? null_resource.setup_new_index.*.triggers.index_hash[1]: "NoIndex"}"
}
