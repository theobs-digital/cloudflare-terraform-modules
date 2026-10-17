mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_custom_page" {
    defaults = {
      id = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415"
      # Settings unlike the ones the tests give, which must win.
      contract_version = 7
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_custom_pages" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_custom_page.this) == 0
    error_message = "Without access_custom_pages, the module must not create any."
  }
}

run "custom_page_minimal" {
  command = plan

  variables {
    access_custom_pages = {
      denied = {
        name        = "Denied"
        type        = "identity_denied"
        custom_html = "<html><body><h1>Access denied</h1></body></html>"
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_custom_page.this["denied"].account_id == var.account_id &&
      cloudflare_zero_trust_access_custom_page.this["denied"].name == "Denied" &&
      cloudflare_zero_trust_access_custom_page.this["denied"].type == "identity_denied" &&
      cloudflare_zero_trust_access_custom_page.this["denied"].custom_html == "<html><body><h1>Access denied</h1></body></html>"
    )
    error_message = "The custom page must belong to account_id, with name, type and custom_html as given."
  }
}

run "custom_page" {
  variables {
    access_custom_pages = {
      login = {
        name             = "Login"
        type             = "login"
        custom_html      = "<html><body><h1>Sign in</h1></body></html>"
        contract_version = 1
      }
    }
  }

  assert {
    condition     = cloudflare_zero_trust_access_custom_page.this["login"].contract_version == 1
    error_message = "contract_version must reach the custom page."
  }

  assert {
    condition     = output.access_custom_page_ids == { login = "f174e90a-fafe-4643-bbbc-4a0ed4fc8415" }
    error_message = "access_custom_page_ids must give the ID of each custom page."
  }
}
