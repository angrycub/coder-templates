# This variable will need to be updated whenever a new team is added to the
# Coder instance.  It is used to determine which team the agent belongs to.
variable "team_name" {
  type        = string
  description = "The name of the team for the Coder agent. Defaults to 'team1'."
  default     = "team1"
  validation {
    condition     = can(regex("^(team1|team2)$", var.team_name))
    error_message = "team_name must be either 'team1' or 'team2'."
  }
}

variable "arch" {
  type        = string
  description = "The architecture the agent will run on. Must be one of: 'amd64', 'arm64'."
  nullable    = false
  validation {
    condition     = can(regex("^(amd64|arm64)$", var.arch))
    error_message = "arch must be one of: 'amd64', 'arm64'."
  }
}

variable "os" {
  type        = string
  description = "The operating system the agent will run on. Must be one of: 'linux', 'darwin', or 'windows'."
  nullable    = false
  validation {
    condition     = can(regex("^(linux|darwin|windows)$", var.os))
    error_message = "os must be one of: 'linux', 'darwin', or 'windows'."
  }
}

# Copy in all the variables that can configure the Coder agent that might have
# optional values.

variable "api_key_scope" {
  type        = string
  description = "Controls what API routes the agent token can access. Options: all (full access) or no_user_data (blocks /external-auth, /gitsshkey, and /gitauth routes). Defaults to 'all'."
  nullable    = true
  default     = null
  validation {
    condition     = var.startup_script_behavior == null  || can(regex("^(all|no_user_data)$", var.api_key_scope))
    error_message = "api_key_scope must be either 'all' or 'no_user_data'."
  }
}

variable "auth" {
  type        = string
  description = "The authentication type the agent will use. Must be one of: 'token', 'google-instance-identity', 'aws-instance-identity', 'azure-instance-identity'. Defaults to 'token'."
  nullable    = true
  default     = null
  validation {
    condition     = var.startup_script_behavior == null  || can(regex("^(token|google-instance-identity|aws-instance-identity|azure-instance-identity)$", var.auth))
    error_message = "auth must be one of: 'token', 'google-instance-identity', 'aws-instance-identity', 'azure-instance-identity'."
  }
}

#TODO: find this default value
variable "connection_timeout" {
  type        = number
  description = "Time in seconds until the agent is marked as timed out when a connection with the server cannot be established. A value of zero never marks the agent as timed out."
  nullable    = true
  default     = null
}

variable "dir" {
  type        = string
  description = "The starting directory when a user creates a shell session. Defaults to $HOME."
  nullable    = true
  default     = null
}

variable "display_apps" {
  type = object({
    port_forwarding_helper = optional(bool),
    ssh_helper             = optional(bool),
    vscode                 = optional(bool),
    vscode_insiders        = optional(bool),
    web_terminal           = optional(bool)
  })
  description = "The list of built-in apps to display in the agent bar."
  nullable    = true
  default     = null
}

variable "env" {
  type        = map(string)
  description = "A mapping of environment variables to set inside the workspace."
  nullable    = true
  default     = null
}

# DEPRECATED in coder_agent provider v1.0.4
# variable "login_before_ready" {
#   type        = bool
#   description = "This option defines whether or not the user can (by default) login to the workspace before it is ready. Ready means that e.g. the startup_script is done and has exited. When enabled, users may see an incomplete workspace when logging in."
#   nullable    = true
#   default     = null
# }

variable "metadata" {
  type = list(object({
    key          = string,
    script       = string,
    interval     = number,
    display_name = optional(string),
    order        = optional(number),
    timeout      = optional(number)
  }))
  description = <<-EOT
    A list of metadata scripts to run in the workspace. Each script runs at a
    specified interval and can be used to collect or report information about
    the workspace.
    Required:
      'key' The key of this metadata item.
      'script' The script that retrieves the value of this metadata item.
      'interval' The interval in seconds at which to refresh this metadata item.
    Optional Values
      'display_name' The user-facing name of this value.
      'order' The order determines the position of agent metadata in the UI
              presentation. The lowest order is shown first and metadata with
              equal order are sorted by key (ascending order).
      'timeout' The maximum time the command is allowed to run in seconds.
  EOT
  nullable    = true
  default     = null
}

variable "motd_file" {
  type        = string
  description = "The path to a file within the workspace containing a message to display to users when they login via SSH. A typical value would be /etc/motd."
  nullable    = true
  default     = null
}

variable "order" {
  type        = number
  description = "The order determines the position of agents in the UI presentation. The lowest order is shown first and agents with equal order are sorted by name (ascending order)."
  nullable    = true
  default     = null
}

variable "resources_monitoring" {
  type = object({
    memory = optional(
      object({
        enabled   = bool,
        threshold = number
     })
    ),
    volume = optional(
      object({
        enabled   = bool,
        path      = string
        threshold = number
      })
    )
   })
  description = "The resources monitoring configuration for this agent. (see below for nested schema)"
  nullable    = true
  default     = null
}

variable "shutdown_script" {
  type        = string
  description = "A script to run before the agent is stopped. The script should exit when it is done to signal that the workspace can be stopped. This option is an alias for defining a 'coder_script' resource with 'run_on_stop' set to 'true'."
  nullable    = true
  default     = null
}

variable "startup_script" {
  type        = string
  description = "A script to run after the agent starts. The script should exit when it is done to signal that the agent is ready. This option is an alias for defining a 'coder_script' resource with 'run_on_start' set to 'true'."
  nullable    = true
  default     = null
}

variable "startup_script_behavior" {
  type        = string
  description = "This option sets the behavior of the startup_script. When set to 'blocking', the startup_script must exit before the workspace is ready. When set to 'non-blocking', the startup_script may run in the background and the workspace will be ready immediately. Default is 'non-blocking', although 'blocking' is recommended."
  default     = null
  nullable    = true
  validation {
    condition     = var.startup_script_behavior == null || can(regex("^(blocking|non-blocking)$", var.startup_script_behavior))
    error_message = "startup_script_behavior must be either 'blocking' or 'non-blocking'."
  }
}

variable "troubleshooting_url" {
  type = string
  description = "A URL to a document with instructions for troubleshooting problems with the agent."
  nullable    = true
  default     = null
}
