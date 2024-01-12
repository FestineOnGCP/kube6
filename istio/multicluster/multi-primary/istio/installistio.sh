#!/bin/bash


CLUSTER1_NAME=gcs-mom
CLUSTER2_NAME=gcs-mom-dev
CLUSTER1_CTX=kind-gcs-mom
CLUSTER2_CTX=kind-gcs-mom-dev
HUB=docker.io/istio
TAG=1.18.1

# download istio images to a host
echo "Pulling istio images to a docker host..."
docker pull $HUB/pilot:$TAG
docker pull $HUB/proxyv2:$TAG

echo "load istio images to the clusters..."
kind load docker-image --name $CLUSTER1_NAME $HUB/pilot:$TAG
kind load docker-image --name $CLUSTER1_NAME $HUB/proxyv2:$TAG

kind load docker-image --name $CLUSTER2_NAME $HUB/pilot:$TAG
kind load docker-image --name $CLUSTER2_NAME $HUB/proxyv2:$TAG

# point this to your latest build binary
istioctl_latest=/usr/local/bin/istioctl

# Install istio iop profile
echo "Installing istio..."
$istioctl_latest install --context="${CLUSTER1_CTX}" -f iop.yaml --skip-confirmation
$istioctl_latest install --context="${CLUSTER2_CTX}" -f iop.yaml --skip-confirmation

# Verify that istio is installed
echo "Verifying istio installation..."
istioctl --context="${CLUSTER1_CTX}" verify-install
istioctl --context="${CLUSTER2_CTX}" verify-install
