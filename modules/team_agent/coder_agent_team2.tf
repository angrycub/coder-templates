resource "coder_agent" "team2" {
  count          = var.team_name == "team2" ? 1 : 0
  os             = var.os
  arch           = var.arch

  # Optional parameters
  # api_key_scope           = var.api_key_scope # Requires coder_agent provider v2.4.2 or later
  auth                    = var.auth
  connection_timeout      = var.connection_timeout
  dir                     = var.dir
  env                     = var.env
  # login_before_ready      = var.login_before_ready # DEPRECATED in coder_agent provider v1.0.4
  motd_file               = var.motd_file
  order                   = var.order
  shutdown_script         = var.shutdown_script
  startup_script          = var.startup_script
  startup_script_behavior = var.startup_script_behavior
  troubleshooting_url     = var.troubleshooting_url

  dynamic "display_apps" {
    for_each = try(tolist(var.display_apps), [])
    content {
      port_forwarding_helper = display_apps.value.port_forwarding_helper
      ssh_helper             = display_apps.value.ssh_helper
      vscode                 = display_apps.value.vscode
      vscode_insiders        = display_apps.value.vscode_insiders
      web_terminal           = display_apps.value.web_terminal
    }
  }

  dynamic "metadata" {
    for_each = try(var.metadata != null ? var.metadata : [])
    content {
      display_name = metadata.value.display_name
      key          = metadata.value.key
      script       = metadata.value.script
      interval     = metadata.value.interval
      timeout      = metadata.value.timeout
      order        = metadata.value.order
    }
  }

  dynamic "resources_monitoring" {
    for_each = try(tolist(var.resources_monitoring), [])
    content {
      dynamic "memory" {
        for_each = try(tolist(resources_monitoring.value.memory), [])
        content {
          enabled   = resources_monitoring.value.memory.enabled
          threshold = resources_monitoring.value.memory.threshold
        }
      }
      dynamic "volume" {
        for_each = try(toset(resources_monitoring.value.volume), [])
        content {
          enabled   = resources_monitoring.value.volume.enabled
          path      = resources_monitoring.value.volume.path
          threshold = resources_monitoring.value.volume.threshold
        }
      }
    }
  }
}
