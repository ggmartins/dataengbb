resource "kubernetes_namespace_v1" "lab" {
  metadata { name = "alb-lab" }
}

resource "kubernetes_config_map_v1" "echo" {
  metadata {
    name      = "echo"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }
  data = { "echo.py" = file("${path.module}/echo.py") }
}

resource "kubernetes_deployment_v1" "echo" {
  metadata {
    name      = "echo"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }
  spec {
    replicas = 2
    selector { match_labels = { app = "echo" } }
    template {
      metadata { labels = { app = "echo" } }
      spec {
        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          seccomp_profile { type = "RuntimeDefault" }
        }
        container {
          name    = "echo"
          image   = "python:3.13-alpine"
          command = ["python", "-B", "/app/echo.py"]
          port { container_port = 8080 }
          resources {
            requests = { cpu = "50m", memory = "32Mi" }
            limits   = { cpu = "250m", memory = "128Mi" }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            capabilities { drop = ["ALL"] }
          }
          volume_mount {
            name       = "app"
            mount_path = "/app"
            read_only  = true
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
          }
        }
        volume {
          name = "app"
          config_map { name = kubernetes_config_map_v1.echo.metadata[0].name }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "echo" {
  metadata {
    name      = "revproxy-service"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }
  spec {
    selector = { app = "echo" }
    type     = var.target_type == "instance" ? "NodePort" : "ClusterIP"
    port {
      port        = 80
      target_port = 8080
    }
  }
}

locals {
  base_annotations = {
    "alb.ingress.kubernetes.io/scheme"                   = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"              = var.target_type
    "alb.ingress.kubernetes.io/group.name"               = local.infra.name
    "alb.ingress.kubernetes.io/load-balancer-name"       = local.infra.name
    "alb.ingress.kubernetes.io/tags"                     = "Environment=lab,Project=${local.infra.name}"
    "alb.ingress.kubernetes.io/subnets"                  = join(",", local.infra.public_subnet_ids)
    "alb.ingress.kubernetes.io/inbound-cidrs"            = local.infra.allowed_cidr
    "alb.ingress.kubernetes.io/listen-ports"             = jsonencode(local.enable_tls ? [{ HTTP = 80 }, { HTTPS = 443 }] : [{ HTTP = 80 }])
    "alb.ingress.kubernetes.io/healthcheck-path"         = "/healthz"
    "alb.ingress.kubernetes.io/success-codes"            = "200"
    "alb.ingress.kubernetes.io/load-balancer-attributes" = "deletion_protection.enabled=false"
  }
  tls_annotations = local.enable_tls ? {
    "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate.server[0].arn
    "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    "alb.ingress.kubernetes.io/ssl-policy"      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    # Explicit off is necessary to disable a previously enabled mTLS listener.
    "alb.ingress.kubernetes.io/mutual-authentication" = jsonencode([
      merge({ port = 443, mode = var.tls_mode == "server" ? "off" : var.tls_mode },
      var.tls_mode == "verify" && var.create_trust_store ? { trustStore = aws_lb_trust_store.client[0].arn } : {})
    ])
  } : {}
}

resource "kubernetes_ingress_v1" "lab" {
  metadata {
    name        = "revproxy-alb"
    namespace   = kubernetes_namespace_v1.lab.metadata[0].name
    annotations = merge(local.base_annotations, local.tls_annotations)
  }
  spec {
    ingress_class_name = "alb"
    rule {
      host = local.enable_tls ? var.hostname : null
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.echo.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
  }
  lifecycle {
    precondition {
      condition     = var.tls_mode != "verify" || var.create_trust_store
      error_message = "Set create_trust_store = true before enabling verify mode."
    }
  }
  wait_for_load_balancer = true
  timeouts {
    create = "15m"
    delete = "15m"
  }
  depends_on = [kubernetes_deployment_v1.echo]
}

output "alb_hostname" {
  value = try(kubernetes_ingress_v1.lab.status[0].load_balancer[0].ingress[0].hostname, "pending")
}
output "alb_name" { value = local.infra.name }
output "namespace" { value = kubernetes_namespace_v1.lab.metadata[0].name }
output "hostname" { value = var.hostname }
