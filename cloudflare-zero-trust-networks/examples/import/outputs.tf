output "unmatched" {
  description = "Keys of the entries that match no existing object, by kind, which the plan creates instead of importing them."
  value = {
    tunnels          = [for key, id in local.existing_tunnel_ids : key if id == null]
    virtual_networks = [for key, id in local.existing_virtual_network_ids : key if id == null]
    routes           = [for key, id in local.existing_route_ids : key if id == null]
    hostname_routes  = [for key, id in local.existing_hostname_route_ids : key if id == null]
    warp_connectors  = [for key in keys(local.warp_connectors) : key if !contains(keys(var.warp_connector_ids), key)]
  }
}
