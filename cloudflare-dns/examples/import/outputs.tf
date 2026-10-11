output "unmatched_records" {
  description = "Keys of `records` that match no existing record, which the plan creates instead of importing them."
  value       = [for key, id in local.existing_ids : key if id == null]
}
