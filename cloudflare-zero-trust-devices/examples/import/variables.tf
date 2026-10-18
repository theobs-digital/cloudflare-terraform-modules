variable "account_id" {
  description = "ID of the Cloudflare account that owns the Zero Trust organization."
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the existing device subnets, by key of local.subnets, from GET /accounts/{account_id}/zerotrust/subnets. The provider has no data source that lists them."
  type        = map(string)
  default     = {}
}

variable "deployment_group_ids" {
  description = "IDs of the existing deployment groups, by key of local.deployment_groups, from GET /accounts/{account_id}/devices/deployment-groups. In provider 5.28.0, the data source that lists them reads the same page again and again, up to max_items."
  type        = map(string)
  default     = {}
}
