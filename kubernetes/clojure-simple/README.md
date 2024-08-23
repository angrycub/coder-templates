---
display_name: Coder Minimal Clojure Workspace
description: Create a minimal clojure workspace by extending a vendor Dockerfile
icon: ../../../site/static/icon/k8s.png
maintainer_github: coder
verified: true
tags: [kubernetes, container]
---

# Coder Minimal Clojure Workspace

Provision Kubernetes Pods as [Coder workspaces][workspaces] with this example
template.

## Prerequisites

Since this template uses a non-public container image (or a likely non-public one),
you will need to configure a Kubernetes secret for the registry credential named
`regcred`.

Store your registry credential as a Kubernetes secret using the
[Pull an Image from a Private Registry guide][] in the Kubernetes documentation.

```
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson
```
or

```
kubectl create secret docker-registry regcred \
  --docker-server=<your-registry-server> \
  --docker-username=<your-name> \
  --docker-password=<your-pword> \
  --docker-email=<your-email>
```

### Infrastructure

**Cluster**: This template requires an existing Kubernetes cluster

**Container Image**: This template includes a Dockerfile that extends the
[`library/clojure:latest`][clojure-img] container to add some basic elements
necessary for Coder to be happy. To add additional tools, extend this image or
build it yourself.

### Authentication

This template authenticates using a `~/.kube/config`, if present on the server,
or via built-in authentication if the Coder provisioner is running on Kubernetes
with an authorized ServiceAccount.  Edit the template if you need to use another
[authentication method][auth-method].

## Architecture

This template provisions the following resources:

- Kubernetes pod (ephemeral)
- Kubernetes persistent volume claim (persistent on `/home/coder`)

This means, when the workspace restarts, any tools or files outside the home
directory are not persisted. Modify the container image to add tools you want to
persist between restarts. Alternatively, individual developers can personalize
their workspaces with [dotfiles](https://coder.com/docs/dotfiles).

> **Note**
> This template is designed to be a starting point! Edit the Terraform to
> extend the template to support your use case.

## Rebuild the Docker container

Use the following command to build the container for multiple architectures

```shell
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag «username»/clojure-simple-multiarch:latest \
  --push \
  .
```

[auth-method]: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#authentication
[clojure-img]: https://hub.docker.com/_/clojure
[k8s-pull]: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
[workspaces]: https://coder.com/docs/workspaces