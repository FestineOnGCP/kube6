#!/bin/bash

. ../../config.sh

# download istio images to a host
echo "Pulling istio images to a docker host..."
docker pull $HUB/pilot:$TAG
docker pull $HUB/proxyv2:$TAG
docker pull docker.io/busybox:1.28

echo "load istio images to the clusters..."
kind load docker-image --name $CLUSTER1_NAME $HUB/pilot:$TAG
kind load docker-image --name $CLUSTER1_NAME $HUB/proxyv2:$TAG
kind load docker-image --name $CLUSTER1_NAME docker.io/busybox:1.28

kind load docker-image --name $CLUSTER2_NAME $HUB/pilot:$TAG
kind load docker-image --name $CLUSTER2_NAME $HUB/proxyv2:$TAG
kind load docker-image --name $CLUSTER2_NAME docker.io/busybox:1.28

# point this to your latest build binary
istioctl_latest=/usr/local/bin/istioctl

# install certs in both clusters
kubectl create namespace istio-system --context=${CLUSTER1_CTX}
# kubectl create secret generic cacerts -n istio-system \
#       --from-file=certs/cluster1/ca-cert.pem \
#       --from-file=certs/cluster1/ca-key.pem \
#       --from-file=certs/cluster1/root-cert.pem \
#       --from-file=certs/cluster1/cert-chain.pem \
#       --context=${CLUSTER1_CTX}

kubectl create namespace istio-system --context=${CLUSTER2_CTX}
# kubectl create secret generic cacerts -n istio-system \
#       --from-file=certs/cluster2/ca-cert.pem \
#       --from-file=certs/cluster2/ca-key.pem \
#       --from-file=certs/cluster2/root-cert.pem \
#       --from-file=certs/cluster2/cert-chain.pem \
#       --context=${CLUSTER2_CTX}

# Install istio iop profile on cluster1
echo "Installing istio in $CLUSTER1_NAME..."
# Install gateway crds
kubectl --context="${CLUSTER1_CTX}" apply -f gateway-crds.yaml
kubectl --context="${CLUSTER1_CTX}" label namespace istio-system topology.istio.io/network=md1-ccmk-naus1

istioctl --context="${CLUSTER1_CTX}" install -f gcs-mom-dev-io.yaml --skip-confirmation

sleep 30

echo "expose services in $CLUSTER1_NAME..."
kubectl --context="${CLUSTER1_CTX}" apply -n istio-system -f expose-mc-svcs.yaml
kubectl --context="${CLUSTER1_CTX}" apply -n istio-system -f auth.yaml

# Install istio profile on cluster2
echo "Installing istio in $CLUSTER2_NAME..."
# Install gateway crds
kubectl --context="${CLUSTER2_CTX}" apply -f gateway-crds.yaml
kubectl --context="${CLUSTER2_CTX}" label namespace istio-system topology.istio.io/network=mp1-ccmk-naus1

istioctl --context="${CLUSTER2_CTX}" install -f gcs-mom-io.yaml --skip-confirmation

sleep 30

echo "expose services in $CLUSTER2_NAME..."
kubectl --context="${CLUSTER2_CTX}" apply -n istio-system -f expose-mc-svcs.yaml
kubectl --context="${CLUSTER1_CTX}" apply -n istio-system -f auth.yaml

## fetch cluster2 controlplan address
#SERVER_CLU2=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' clu2-control-plane)

# Enable Endpoint Discovery
echo "Enable Endpoint Discovery..."
istioctl create-remote-secret \
    --context="${CLUSTER2_CTX}" \
    --name="${CLUSTER2_NAME}" \
    --server=https://"${CLUSTER2_NAME}"-control-plane:6443 | \
    kubectl apply -f - --context="${CLUSTER1_CTX}"

istioctl create-remote-secret \
    --context="${CLUSTER1_CTX}" \
    --name="${CLUSTER1_NAME}"\
    --server=https://"${CLUSTER1_NAME}"-control-plane:6443 | \
    kubectl apply -f - --context="${CLUSTER2_CTX}"
