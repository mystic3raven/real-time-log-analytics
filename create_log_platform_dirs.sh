#!/bin/bash

# Base directory to create the hierarchy in
BASE_DIR="$1"

if [[ -z "$BASE_DIR" ]]; then
    echo "Usage: $0 <base_directory>"
    exit 1
fi

echo "Creating log analytics directory hierarchy under: $BASE_DIR"

mkdir -p "$BASE_DIR/k8s-manifests/kafka"
mkdir -p "$BASE_DIR/k8s-manifests/logstash"
mkdir -p "$BASE_DIR/k8s-manifests/elasticsearch"
mkdir -p "$BASE_DIR/k8s-manifests/kibana"
mkdir -p "$BASE_DIR/k8s-manifests/grafana"
mkdir -p "$BASE_DIR/k8s-manifests/rancher-config"

mkdir -p "$BASE_DIR/docker/custom-logstash"
mkdir -p "$BASE_DIR/docker/custom-kibana"

mkdir -p "$BASE_DIR/python-scripts"
mkdir -p "$BASE_DIR/shell-scripts"

mkdir -p "$BASE_DIR/terraform"
mkdir -p "$BASE_DIR/docs"

touch "$BASE_DIR/.gitignore"

echo "All directories created successfully!"
