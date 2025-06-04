
variable "use_kubeconfig" {
  type        = bool
  description = <<-EOF
    Use host kubeconfig? (true/false)

    Set this to false if the Coder host is itself running as a Pod on the same
    Kubernetes cluster as you are deploying workspaces to.

    Set this to true if the Coder host is running outside the Kubernetes cluster
    for workspaces.  A valid "~/.kube/config" must be present on the Coder host.
  EOF
  default     = false
}

variable "namespace" {
  type        = string
  description = <<-EOF
    The Kubernetes namespace to create workspaces in (must exist
    prior to creating workspaces). If the Coder host is itself running as a Pod
    on the same Kubernetes cluster as you are deploying workspaces to, set this
    to the same namespace.
  EOF
  default     = "coder"
}

# Ordinarily, you would use a Terraform variable to set the team name, but for
# this example, we'll comment it out and use a coder_parameter instead.

# variable "team_name" {
#   type        = string
#   description = <<-EOF
#     The name of the team for the Coder agent. Defaults to 'team1'.
#   EOF
#   default     = "team1"
# }

data "coder_parameter" "team_name" {
  name         = "team_name"
  display_name = "Team Name"
  default      = "team1"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "team1"
    value = "team1"
  }
  option {
    name  = "team2"
    value = "team2"
  }
}

# This local variable allows you to easily swap between the coder_parameter and
# a variable for the team name. If you want to use a variable instead, you can
# uncomment the variable block above and comment out the data block below, and
# then uncomment the line in the locals block.
locals {
  # team_name = var.team_name
  team_name = data.coder_parameter.team_name.value
}