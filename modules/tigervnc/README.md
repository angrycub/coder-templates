---
display_name: TigerVNC
description: A modern open source VNC server
icon: ../../../../.icons/tigervnc.svg
maintainer_github: coder
verified: true
tags: [vnc, desktop, tigervnc]
---

# TigerVNC

Automatically install [TigerVNC](https://tigervnc.org/) in a workspace,
and create an app to access it via the dashboard.

```tf
module "tigervnc" {
  count               = data.coder_workspace.me.start_count
  source              = "registry.coder.com/coder/tigervnc"
  version             = "1.0.0"
  agent_id            = coder_agent.example.id
  desktop_environment = "xfce"
}
```

> **Note:** This module only works on workspaces with a pre-installed desktop
> environment. As an example base image you can use `codercom/enterprise-desktop`
> image.
