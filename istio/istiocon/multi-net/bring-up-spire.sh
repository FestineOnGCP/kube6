#/bin/bash

export CTX_CLUSTER1=kind-gcs-mom-dev
export CTX_CLUSTER2=kind-gcs-mom

# set -e

kubectl config use-context ${CTX_CLUSTER1}
# kubectl create ns istio-system
# until kubectl apply -f ./spire/crds.yaml; do sleep 3; done
# kubectl apply -f ./spire/configmaps.yaml
kubectl apply -f ./spire/spire-gcs-mom-dev.yaml
echo "sleeping..."
# sleep 30
kubectl apply -f ./spire/spiffe-id-gcs-mom-dev.yaml
DEV_POD="$(kubectl get pod -n spire -l app=spire-server -ojsonpath='{ .items[0].metadata.name }')"
gcs_mom_dev_bundle="$(kubectl exec --stdin $DEV_POD -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe)"
echo "$gcs_mom_dev_bundle"
kubectl -n spire expose svc spire-server-bundle-endpoint --port 8443 --target-port 8443 --name bundle-api --type LoadBalancer


kubectl config use-context ${CTX_CLUSTER2}
# kubectl create ns istio-system
# until kubectl apply -f ./spire/crds.yaml; do sleep 3; done
# kubectl apply -f ./spire/configmaps.yaml
kubectl apply -f ./spire/spire-gcs-mom.yaml
echo "sleeping..."
# sleep 30
kubectl apply -f ./spire/spiffe-id-gcs-mom.yaml
PROD_POD="$(kubectl get pod -n spire -l app=spire-server -ojsonpath='{ .items[0].metadata.name }')"
gcs_mom_bundle="$(kubectl exec --stdin $PROD_POD -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe)"
echo "$gcs_mom_bundle"
kubectl -n spire expose svc spire-server-bundle-endpoint --port 8443 --target-port 8443 --name bundle-api --type LoadBalancer

# sleep 10
# Set example.org bundle to domain.test SPIRE bundle endpoint
kubectl exec --stdin "$PROD_POD" -c spire-server -n spire -- /opt/spire/bin/spire-server  bundle set -format spiffe -id spiffe://md1-ccmk-naus1.com <<< "$gcs_mom_dev_bundle"
### move to cluster 1
kubectl config use-context ${CTX_CLUSTER1}
# Set domain.test bundle to example.org SPIRE bundle endpoint
kubectl exec --stdin "$DEV_POD" -c spire-server -n spire -- /opt/spire/bin/spire-server  bundle set -format spiffe -id spiffe://mp1-ccmk-naus1.com <<< "$gcs_mom_bundle"


