#!/bin/bash

export CTX_CLUSTER1=kind-gcs-mom-dev
export CTX_CLUSTER2=kind-gcs-mom

kubectl config use-context ${CTX_CLUSTER1}
kubectl delete -f crds.yaml
kubectl delete -f spire-gcs-mom-dev.yaml
kubectl delete -f spiffe-id-gcs-mom-dev.yaml
# kubectl delete ns istio-system

kubectl config use-context ${CTX_CLUSTER2}
kubectl delete -f crds.yaml
kubectl delete -f spire-gcs-mom.yaml
kubectl delete -f spiffe-id-gcs-mom.yaml
# kubectl delete ns istio-system

