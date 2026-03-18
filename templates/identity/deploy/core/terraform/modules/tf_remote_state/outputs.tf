output "remote_states" {
  description = "Map of all remote state data sources"
  value       = data.terraform_remote_state.remote_states
}

output "remote_state_outputs" {
  description = "Map of remote state outputs by region/environment"
  value = {
    for key, state in data.terraform_remote_state.remote_states : key => state.outputs
  }
}

# Organized outputs by service type and region
output "management_remote_states" {
  description = "Management remote states organized by region"
  value = {
    for key, state in data.terraform_remote_state.remote_states :
    replace(key, "management_", "") => state.outputs
    if startswith(key, "management_")
  }
}

output "connectivity_remote_states" {
  description = "Connectivity remote states organized by region"
  value = {
    for key, state in data.terraform_remote_state.remote_states :
    replace(key, "connectivity_", "") => state.outputs
    if startswith(key, "connectivity_")
  }
}

output "identity_remote_states" {
  description = "Identity remote states organized by region"
  value = {
    for key, state in data.terraform_remote_state.remote_states :
    replace(key, "identity_", "") => state.outputs
    if startswith(key, "identity_")
  }
}
