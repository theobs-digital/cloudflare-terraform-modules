variable "account_id" {
  description = "ID of the test account, whose Zero Trust organization must exist."
  type        = string
}

variable "zone" {
  description = "A zone of the test account. Applications and the MCP portal take names under tf-test-ci.<zone>, which need no DNS record."
  type        = string
}

variable "entra_client_secret" {
  description = "Client secret of the test Entra ID provider, which points to no real directory."
  type        = string
  default     = "tf-test-ci-not-a-secret"
  sensitive   = true
}
