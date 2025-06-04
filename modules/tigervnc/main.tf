terraform {
  required_version = ">= 1.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 0.12"
    }
  }
}

variable "agent_id" {
  type        = string
  description = "The ID of a Coder agent."
}

variable "port" {
  type        = number
  description = "The port to run TigerVNC on."
  default     = 6800
}

variable "tiger_version" {
  type        = string
  description = "Version of TigerVNC to install."
  default     = "1.3.2"
}

variable "desktop_environment" {
  type        = string
  description = "Specifies the desktop environment of the workspace. This should be pre-installed on the workspace."
  validation {
    condition     = contains(["xfce", "kde", "gnome", "lxde", "lxqt"], var.desktop_environment)
    error_message = "Invalid desktop environment. Please specify a valid desktop environment."
  }
}

variable "subdomain" {
  type        = bool
  description = "Is subdomain sharing enabled?"
  default     = true
}


variable "debug" {
  type        = bool
  description = "Write debug information to the workspace logs."
  default     = false
}


resource "coder_script" "tiger_vnc" {
  agent_id     = var.agent_id
  display_name = "TigerVNC"
  icon         = "/icon/desktop.svg"
  run_on_start = true

  script = templatefile("${path.module}/run.tftpl.sh", {
    PORT                = var.port,
    TIGER_VERSION       = var.tiger_version,
    DESKTOP_ENVIRONMENT = var.desktop_environment
    SUBDOMAIN           = tostring(var.subdomain)
    PATH_VNC_HTML       = file("${path.module}/path_vnc.html")
    DEBUG               = tostring(var.debug)
  })
}

resource "coder_app" "tiger_vnc" {
  agent_id     = var.agent_id
  slug         = "tiger-vnc"
  display_name = "TigerVNC"
  url          = "http://localhost:${var.port}"
  icon         = "/icon/desktop.svg"
  subdomain    = var.subdomain
  share        = "owner"
  open_in      = "tab"

  healthcheck {
    url       = "http://localhost:${var.port}/app"
    interval  = 5
    threshold = 5
  }
}
