mock_provider "cloudflare" {
  mock_resource "cloudflare_zone_dnssec" {
    defaults = {
      algorithm        = "13"
      digest           = "48E939042E82C22542CB377B580DFDC52A361CEFDC72E7F9107E2B6BD9306A45"
      digest_algorithm = "SHA256"
      digest_type      = "2"
      ds               = "example.com. 3600 IN DS 16953 13 2 48E939042E82C22542CB377B580DFDC52A361CEFDC72E7F9107E2B6BD9306A45"
      flags            = 257
      key_tag          = 16953
      key_type         = "ECDSAP256SHA256"
      public_key       = "oXiGYrSTO+LSCJ3mohc8EP+CzF9KxBj8/ydXJ22pKuZP3VAC3/Md/k7xZfz470CoRyZJ6gV6vml07IC3d8xqhA=="
    }
  }
}

variables {
  account_id = "023e105f4ecef8ad9ca31a8372d0c353"
  name       = "example.com"
}

run "dnssec_left_alone" {
  command = plan

  assert {
    condition     = length(cloudflare_zone_dnssec.this) == 0 && output.dnssec == null
    error_message = "Without dnssec, the module must not manage DNSSEC, and the dnssec output must be null."
  }
}

run "dnssec" {
  variables {
    dnssec = {
      status              = "active"
      dnssec_multi_signer = false
      dnssec_presigned    = false
      dnssec_use_nsec3    = true
    }
  }

  assert {
    condition     = cloudflare_zone_dnssec.this[0].zone_id == output.zone_id
    error_message = "DNSSEC must apply to the zone of the module."
  }

  assert {
    condition = (
      cloudflare_zone_dnssec.this[0].status == "active" &&
      cloudflare_zone_dnssec.this[0].dnssec_multi_signer == false &&
      cloudflare_zone_dnssec.this[0].dnssec_presigned == false &&
      cloudflare_zone_dnssec.this[0].dnssec_use_nsec3 == true
    )
    error_message = "status, dnssec_multi_signer, dnssec_presigned and dnssec_use_nsec3 must reach DNSSEC."
  }

  assert {
    condition     = output.dnssec.status == "active" && output.dnssec.ds == "example.com. 3600 IN DS 16953 13 2 48E939042E82C22542CB377B580DFDC52A361CEFDC72E7F9107E2B6BD9306A45"
    error_message = "The dnssec output must give the status and the DS record."
  }

  assert {
    condition = (
      output.dnssec.key_tag == 16953 &&
      output.dnssec.algorithm == "13" &&
      output.dnssec.digest_type == "2" &&
      output.dnssec.digest_algorithm == "SHA256" &&
      output.dnssec.digest == "48E939042E82C22542CB377B580DFDC52A361CEFDC72E7F9107E2B6BD9306A45"
    )
    error_message = "The dnssec output must give the fields of the DS record."
  }

  assert {
    condition = (
      output.dnssec.flags == 257 &&
      output.dnssec.key_type == "ECDSAP256SHA256" &&
      output.dnssec.public_key == "oXiGYrSTO+LSCJ3mohc8EP+CzF9KxBj8/ydXJ22pKuZP3VAC3/Md/k7xZfz470CoRyZJ6gV6vml07IC3d8xqhA=="
    )
    error_message = "The dnssec output must give the DNSKEY fields."
  }
}

run "dnssec_on_adopted_zone" {
  command = plan

  variables {
    create_zone = false
    dnssec      = { status = "active" }
  }

  assert {
    condition     = cloudflare_zone_dnssec.this[0].zone_id == data.cloudflare_zone.this[0].id
    error_message = "DNSSEC must apply to the looked-up zone."
  }
}
