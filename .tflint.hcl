config {
  # Lint the examples through the module they call.
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}
