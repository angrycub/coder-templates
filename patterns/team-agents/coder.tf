
provider "coder" {}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  dynamic "option" {
    for_each = range(2,10,2)
    content {
      name  = "${option.value} Cores"
      value = "${option.value}"
    }
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  dynamic "option" {
    for_each = range(2,10,2)
    content {
      name  = "${option.value} GB"
      value = "${option.value}"
    }
  }
}

data "coder_parameter" "home_disk_size" {
  name         = "home_disk_size"
  display_name = "Home disk size"
  description  = "The size of the home disk in GB"
  default      = "10"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 1
    max = 250
  }
}

module "team_agent" {
  source = "./modules/team_agent"

  # The agent name is used to identify the agent in the Coder UI
  team_name = local.team_name

  # The OS and architecture of the agent
  os   = "linux"
  arch = "amd64"

  # The startup script to run when the agent starts
  startup_script = <<-EOT
    echo "Running agent's startup_script..."
    echo "Agent's startup_script complete."
  EOT
}

module "code-server" {
  count     = data.coder_workspace.me.start_count
  source    = "registry.coder.com/coder/code-server/coder"
  version   = "1.2.0"
  agent_id  = module.team_agent.agent.id
  open_in   = "tab"
  subdomain = "true"
}
