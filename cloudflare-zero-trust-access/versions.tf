terraform {
  # 1.3: optional object attributes.
  required_version = ">= 1.3"

  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      # The release the module is tested with.
      version = "~> 5.28"
    }
  }
}
