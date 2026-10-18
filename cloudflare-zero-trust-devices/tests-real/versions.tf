terraform {
  required_version = ">= 1.3"

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      # No lock file: each run takes the newest 5.x the module accepts.
      version = "~> 5.28"
    }
  }
}
