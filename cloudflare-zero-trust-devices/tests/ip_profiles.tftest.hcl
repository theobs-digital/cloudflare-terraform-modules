mock_provider "cloudflare" {}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
}

run "ip_profiles_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zero_trust_device_subnet.this) == 0
    error_message = "Without device_subnets, the module must not manage any device subnet."
  }

  assert {
    condition     = length(cloudflare_zero_trust_device_ip_profile.this) == 0
    error_message = "Without device_ip_profiles, the module must not manage any device IP profile."
  }
}

# Booleans are true: the mock fills a bool left out with false.
run "subnets" {
  variables {
    device_subnets = {
      engineering = {
        name               = "Engineering"
        network            = "100.80.0.0/16"
        comment            = "Engineering laptops"
        is_default_network = true
      }
      contractors = {
        name    = "Contractors"
        network = "10.20.0.0/24"
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_subnet.this["engineering"].account_id == var.account_id &&
      cloudflare_zero_trust_device_subnet.this["engineering"].name == "Engineering" &&
      cloudflare_zero_trust_device_subnet.this["engineering"].network == "100.80.0.0/16" &&
      cloudflare_zero_trust_device_subnet.this["engineering"].comment == "Engineering laptops" &&
      cloudflare_zero_trust_device_subnet.this["engineering"].is_default_network == true
    )
    error_message = "Every attribute must reach the device subnet."
  }

  assert {
    condition = output.device_subnet_ids == {
      engineering = cloudflare_zero_trust_device_subnet.this["engineering"].id
      contractors = cloudflare_zero_trust_device_subnet.this["contractors"].id
    }
    error_message = "device_subnet_ids must give the ID of each device subnet, by key."
  }
}

# subnet_id comes from the device_subnet_ids output, as a caller writes it.
# The subnets are those of the previous run, unchanged, so they keep their IDs.
run "ip_profiles" {
  variables {
    device_subnets = {
      engineering = {
        name               = "Engineering"
        network            = "100.80.0.0/16"
        comment            = "Engineering laptops"
        is_default_network = true
      }
      contractors = {
        name    = "Contractors"
        network = "10.20.0.0/24"
      }
    }
    device_ip_profiles = {
      engineering = {
        name        = "Engineering"
        match       = "identity.groups.name == \"Engineering\""
        precedence  = 100
        subnet_id   = run.subnets.device_subnet_ids["engineering"]
        description = "Engineering laptops"
        enabled     = true
      }
      contractors = {
        name       = "Contractors"
        match      = "identity.email matches \".*@contractor.example\""
        precedence = 200
        subnet_id  = run.subnets.device_subnet_ids["contractors"]
      }
    }
  }

  assert {
    condition = (
      cloudflare_zero_trust_device_ip_profile.this["engineering"].account_id == var.account_id &&
      cloudflare_zero_trust_device_ip_profile.this["engineering"].name == "Engineering" &&
      cloudflare_zero_trust_device_ip_profile.this["engineering"].match == "identity.groups.name == \"Engineering\"" &&
      cloudflare_zero_trust_device_ip_profile.this["engineering"].precedence == 100 &&
      cloudflare_zero_trust_device_ip_profile.this["engineering"].description == "Engineering laptops" &&
      cloudflare_zero_trust_device_ip_profile.this["engineering"].enabled == true
    )
    error_message = "Every attribute must reach the device IP profile."
  }

  assert {
    condition = alltrue([
      for key in ["engineering", "contractors"] :
      cloudflare_zero_trust_device_ip_profile.this[key].subnet_id == cloudflare_zero_trust_device_subnet.this[key].id
    ])
    error_message = "A device IP profile must reach the subnet that subnet_id names."
  }

  assert {
    condition = output.device_ip_profile_ids == {
      engineering = cloudflare_zero_trust_device_ip_profile.this["engineering"].id
      contractors = cloudflare_zero_trust_device_ip_profile.this["contractors"].id
    }
    error_message = "device_ip_profile_ids must give the ID of each device IP profile, by key."
  }
}
