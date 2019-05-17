output "history_index_id" {
  value = "${null_resource.setup_new_index.*.triggers.index_hash[0]}"
}

output "snapshot_index_id" {
  value = "${null_resource.setup_new_index.*.triggers.index_hash[1]}"
}
