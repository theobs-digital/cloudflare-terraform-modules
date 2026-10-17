# The API token comes from the CLOUDFLARE_API_TOKEN environment variable.
provider "cloudflare" {}

module "access" {
  source = "../.."

  account_id = var.account_id

  access_policies = {
    staff = {
      name     = "Staff"
      decision = "allow"
      include  = [{ email_domain = { domain = "example.com" } }]
    }
  }

  access_applications = {
    wiki = {
      name         = "Wiki"
      type         = "self_hosted"
      destinations = [{ type = "public", uri = "wiki.example.com" }]
      policies     = [{ id = module.access.access_policy_ids["staff"] }]
    }
  }
}
