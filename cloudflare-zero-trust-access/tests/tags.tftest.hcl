mock_provider "cloudflare" {
  mock_resource "cloudflare_zero_trust_access_tag" {
    defaults = {
      # Unlike the name the tests give, so that the output must read the ID.
      id = "Computed"
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "no_tags" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_access_tag.this) == 0
    error_message = "Without access_tags, the module must not create any."
  }
}

run "tag" {
  variables {
    access_tags = {
      engineering = { name = "Engineering" }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_access_tag.this["engineering"].account_id == var.account_id &&
      cloudflare_zero_trust_access_tag.this["engineering"].name == "Engineering"
    )
    error_message = "The tag must belong to account_id, with name as given."
  }

  assert {
    condition     = output.access_tag_ids == { engineering = "Computed" }
    error_message = "access_tag_ids must give the ID of each tag."
  }
}
