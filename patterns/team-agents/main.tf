terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# These local variables are consulted by the Kubernetes resources to
# create the root CA secret and certificate for the workspace.
# You can change these to suit your needs, but ensure that the secret
# name matches the one used in the `kubernetes_deployment` resource.
locals {
  ca_secret_name = "root-ca-secret"
  ca_cert_name   = "Gerbidigm_Root_CA"
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount,
  # depending on admin preferences
  config_path = var.use_kubeconfig == true ? "~/.kube/config" : null
}

locals {
  annotations = {
    "com.coder.user.email"       = data.coder_workspace_owner.me.email
  }

  common_labels = {
    "app.kubernetes.io/part-of"  = "coder"
    "com.coder.resource"         = "true"
    "com.coder.workspace.id"     = data.coder_workspace.me.id
    "com.coder.workspace.name"   = data.coder_workspace.me.name
    "com.coder.user.id"          = data.coder_workspace_owner.me.id
    "com.coder.user.username"    = data.coder_workspace_owner.me.name
  }

  ws_labels = merge(
    local.common_labels,
    {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${data.coder_workspace.me.id}"
    }
  )

  pvc_labels = merge(
    local.common_labels,
    {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${data.coder_workspace.me.id}"
    }
  )
}

locals {
  prefix = "coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.me.name}"
}

resource "kubernetes_persistent_volume_claim" "home" {
  wait_until_bound = false

  metadata {
    name        = "${local.prefix}-home"
    namespace   = var.namespace
    labels      = local.pvc_labels
    annotations = local.annotations
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "${data.coder_parameter.home_disk_size.value}Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "main" {
  count            = data.coder_workspace.me.start_count
  wait_for_rollout = false

  depends_on = [
    kubernetes_persistent_volume_claim.home
  ]

  metadata {
    name        = "${local.prefix}"
    namespace   = var.namespace
    labels      = local.ws_labels
    annotations = local.annotations
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.ws_labels
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = local.ws_labels
      }

      spec {
        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }

        container {
          name              = "dev"
          image             = "codercom/enterprise-base:ubuntu"
          image_pull_policy = "Always"
          command           = [
            "sh",
            "-c",
            <<-EOT
              sudo apt install ca-certificates
              sudo update-ca-certificates
              ${module.team_agent.agent.init_script}
            EOT
          ]

          security_context {
            run_as_user = 1000
          }

          env {
            name  = "CODER_AGENT_TOKEN"
            value = module.team_agent.agent.token
          }

          resources {
            requests = {
              "cpu"    = "250m"
              "memory" = "512Mi"
            }

            limits = {
              "cpu"    = "${data.coder_parameter.cpu.value}"
              "memory" = "${data.coder_parameter.memory.value}Gi"
            }
          }

          volume_mount {
            mount_path = "/home/coder"
            name       = "home"
            read_only  = false
          }

          volume_mount {
            name       = "ca"
            read_only  = true
            mount_path = "/usr/local/share/ca-certificates/${local.ca_cert_name}.crt"
            sub_path   = "tls.crt"
          }
        }

        volume {
          name = "home"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.home.metadata.0.name
            read_only  = false
          }
        }

        volume {
          name = "ca"
          secret {
            secret_name = local.ca_secret_name
          }
        }

        affinity {
          // This affinity attempts to spread out all workspace pods evenly across
          // nodes.
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1

              pod_affinity_term {
                topology_key = "kubernetes.io/hostname"

                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["coder-workspace"]
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
