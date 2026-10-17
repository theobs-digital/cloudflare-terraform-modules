variable "account_id" {
  description = "ID of the test account, whose Zero Trust organization must exist."
  type        = string
}

variable "zone" {
  description = "A zone of the test account. Ingress rules take hostnames under tf-test-ci.<zone>, which need no DNS record."
  type        = string
}

variable "tunnel_secret" {
  description = "Secret of the tf-test-ci-lyon tunnel, such as the output of `openssl rand -base64 32`. Pass the same value to apply, plan and destroy: Cloudflare never returns it, and another value plans an update."
  type        = string
  sensitive   = true
}
