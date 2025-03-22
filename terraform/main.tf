module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "log-analytics-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}

module "helm-charts" {
  source = "./modules/helm"
}
# Enable CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "log-platform-trail"
  s3_bucket_name                = aws_s3_bucket.tf_state.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cw_role.arn
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail.arn
  depends_on                    = [aws_s3_bucket.tf_state]
}

# IAM Role for CloudTrail to push logs to CloudWatch
resource "aws_iam_role" "cloudtrail_cw_role" {
  name = "cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs_policy" {
  name = "cloudtrail-logs-policy"
  role = aws_iam_role.cloudtrail_cw_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/log-platform"
  retention_in_days = 30
}

# CloudWatch Container Insights (CloudWatch agent for EKS)
resource "helm_release" "cloudwatch_agent" {
  name             = "cloudwatch-agent"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-cloudwatch-metrics"
  namespace        = "amazon-cloudwatch"
  create_namespace = true

  values = [
    yamlencode({
      clusterName               = var.cluster_name,
      region                    = var.aws_region,
      metricsCollectionInterval = 60,
      enhancedContainerInsights = true
    })
  ]
}

# AWS X-Ray DaemonSet
resource "kubernetes_daemonset" "xray" {
  metadata {
    name      = "xray-daemon"
    namespace = "observability"
    labels = {
      app = "xray-daemon"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "xray-daemon"
      }
    }

    template {
      metadata {
        labels = {
          app = "xray-daemon"
        }
      }

      spec {
        container {
          name  = "xray-daemon"
          image = "public.ecr.aws/xray/aws-xray-daemon:latest"

          ports {
            container_port = 2000
            protocol       = "UDP"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }
}


# === Prometheus Helm Chart ===
resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  values = [
    yamlencode({
      grafana = {
        enabled       = true
        adminPassword = "admin" # Replace with a secret in production
        service = {
          type = "LoadBalancer"
        }
      },
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
        }
      }
    })
  ]
}
