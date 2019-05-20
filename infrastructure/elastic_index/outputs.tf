output "history_index_id" {
  value = "${null_resource.setup_new_index.*.triggers.index_hash[index(local.flavours, "history")]}"
}

output "snapshot_index_id" {
  value = "${null_resource.setup_new_index.*.triggers.index_hash[index(local.flavours, "snapshot")]}"
}
