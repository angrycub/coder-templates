
# Each agent has to be a full duplication of the team-specific Terraform file
# (coder_agent_team1.tf for example). This is because Terraform does not support
# dynamic resource labeling, thus preventing us from using for_each to enable
# reuse.

# To add a new team:
#
# 1. Create a new file named `coder_agent_TeamAlias.tf` where `TeamAlias` is the
#    team name.
#
# 2. Copy the contents of `coder_agent_team1.tf` into the new file.
#
# 3. Update the `coder_agent` resource's label and `count` condition to match the
#    new team name.
#
# 4. Add a reference to the newly defined `coder_agent` resource in the `locals`
#    block below where noted.
#
# 5. Update the `variables.tf` file to include the new team name in the `team_name`
#    variable's validation condition and error message.

output "coder_agent_team1" {
  value       = coder_agent.team1
}

output "coder_agent_team2" {
  value       = coder_agent.team2
}

locals {
  team_agent = try(
    # NOTE: As you add team agent templates, you will need to add them to
    # this list. Ensure that you add the `[0]` index to each `coder_agent`
    # resource to reference the first (if any) instance.
    coder_agent.team1[0],
    coder_agent.team2[0]
  )
}

terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
  }
}
