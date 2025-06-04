---
display_name: "Demo: Dynamic Agent Names"
description: "Using a Terraform module to create agents with \"dynamic\" agent names for different teams"
icon: ../../../site/static/icon/coder.png
maintainer_github: coder
verified: true
tags: [demo, modules, kubernetes]
---

# Demo Template: Using a module to simulate dynamic agent names

**This demo template provisions [Coder workspaces][] using a Kubernetes
Deployment, with a focus on using a Terraform module to create agents with
"dynamic" agent names for different teams.**

## Why use a module for dynamic agent names

Terraform does not support dynamic resource labels or names, which means you
cannot use variables or expressions to generate resource names on the fly. This
module-based approach works around that limitation by defining a separate
resource block for each possible team, allowing the template to provision the
correct agent based on the selected team name.

- The template is designed to demonstrate a pattern for managing Terraform
  resources that use the label as their name.

- The template uses a Terraform module to define separate Coder agents for each
  team (e.g., `team1`, `team2`), allowing you to select a team name at workspace
  creation with coder_parameters or as a template administrator using Terraform
  variables.

- The structure is modular, so you can add more teams by duplicating and
  modifying the agent module files.

## Prerequisites

- Coder installation using Kubernetes

## Architecture

This template provisions the following resources:

- PersistentVolumeClaim for home directory (persistent on `/home/coder`)

- Deployment
  - Pod for the workspace (ephemeral)
    - TLS certificate mount from a Kubernetes secret for self-signed certificates
    - Mount for the /home/coder directory
    - Coder agent for the selected team

> **Note** This template is designed to demonstrate a Terraform pattern!
> It is not production-ready and should not be used as-is for real-world
> deployments.

## Demonstration

### Upload the template

If you haven't already, upload the `team_agents` template to your Coder
installation. You can do this by using the Coder UI or the Coder CLI.

### Create a workspace

#### Create a team1 workspace

Create a new workspace named `team1-demo` using this template. Select `team1`

> **Note**: In a production-type environment, you would likely want to switch
> to using Terraform variables for `team_name` instead of coder_parameters to
> avoid exposing the list of teams to end users. This demo template is designed
> to demonstrate the use of coder_parameters for simplicity and ease of use.

When the workspace is created and provisioned, note that the agent name is
`team1`. You can verify this by checking the workspace details in the Coder UI.

Open the `code-server` application by clicking the button in the workspace page.
This instance of `code-server` is configured to use subdomain routing, so it will
be accessible at
`https://code-server--team1--team1-demo--<your-user-name>.<your-coder-domain>`.

#### Create a team2 workspace

Create a new workspace named `team2-demo` using this template. Select `team2`

When the workspace is created and provisioned, note that the agent name is
`team2`. You can verify this by checking the workspace details in the Coder UI.

Open the `code-server` application by clicking the button in the workspace page.
This instance of `code-server` is configured to use subdomain routing, so it will
be accessible at
`https://code-server--team2--team2-demo--<your-user-name>.<your-coder-domain>`.

## Adding a Team

To add a new team to the `team_agent` module, follow these steps:

### 1. Create a new agent file

- In `modules/team_agent/`, copy `coder_agent_team1.tf` to a new file named
  `coder_agent_<team-name>.tf`, replacing `<team-name>` with your new team's
  name (e.g., `team3`).

### 2. Update the resource

- In your new file, update the label for the `resource "coder_agent"` block to
  use your new team name.

- Change the `count` condition to match your new team name (e.g., `count =
  var.team_name == "team3" ? 1 : 0`).

### 3. Reference the new agent

- In `modules/team_agent/main.tf`, add an output for your new agent (following
  the pattern for `team1` and `team2`).

- Add your new agent to the `locals.team_agent` list, referencing the first
  instance (e.g., `coder_agent.team3[0]`).

### 4. Update the team_name parameter

- In `variables.tf`, add your new team to the `coder_parameter` options for
  `team_name`.

[Coder workspaces]: https://coder.com/docs/workspaces
