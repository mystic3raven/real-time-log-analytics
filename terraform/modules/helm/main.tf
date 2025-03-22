resource "helm_release" "kafka" {
  name             = "kafka"
  chart            = "bitnami/kafka"
  repository       = "https://charts.bitnami.com/bitnami"
  namespace        = "logging"
  create_namespace = true

  values = [file("${path.module}/kafka-values.yaml")]
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  chart      = "elastic/elasticsearch"
  repository = "https://helm.elastic.co"
  namespace  = "logging"

  values = [file("${path.module}/elasticsearch-values.yaml")]
}

resource "helm_release" "kibana" {
  name       = "kibana"
  chart      = "elastic/kibana"
  repository = "https://helm.elastic.co"
  namespace  = "logging"

  values = [file("${path.module}/kibana-values.yaml")]
}

resource "helm_release" "logstash" {
  name       = "logstash"
  chart      = "elastic/logstash"
  repository = "https://helm.elastic.co"
  namespace  = "logging"

  values = [file("${path.module}/logstash-values.yaml")]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana/grafana"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = "logging"

  values = [file("${path.module}/grafana-values.yaml")]
}
