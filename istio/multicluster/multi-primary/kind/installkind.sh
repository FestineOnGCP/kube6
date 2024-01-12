#!/bin/bash

# Exit script if kind not installed
if ! command -v kind &> /dev/null
then
  echo "Kind not found, please install out of script..."
  exit 1
fi

CLUSTER1_NAME=gcs-mom
CLUSTER2_NAME=gcs-mom-dev


# Create cluster1 cluster
echo "Creating cluster $CLUSTER1_NAME..."
kind create cluster --name $CLUSTER1_NAME --config cluster.yaml


# Create cluster2 cluster
echo "Creating cluster $CLUSTER2_NAME..."
kind create cluster --name $CLUSTER2_NAME --config cluster.yaml


# Verify that the cluster is running
echo "Verifying cluster $CLUSTER1_NAME..."
kubectl cluster-info --context kind-$CLUSTER1_NAME

# Get the list of kind nodes
nodes=$(kind get nodes --name $CLUSTER1_NAME)

# Loop through each node and update the inotify parameters
for node in $nodes; do
  echo "Updating inotify parameters on $node..."
  docker exec $node sysctl -w fs.inotify.max_user_instances=1024
  docker exec $node sysctl -w fs.inotify.max_user_watches=1048576
  docker exec $node apt update
  docker exec $node apt install -y tcpdump
done

# Verify that the cluster is running
echo "Verifying cluster $CLUSTER2_NAME..."
kubectl cluster-info --context kind-$CLUSTER2_NAME

# Get the list of kind nodes
nodes=$(kind get nodes --name $CLUSTER2_NAME)

# Loop through each node and update the inotify parameters
for node in $nodes; do
  echo "Updating inotify parameters on $node..."
  docker exec $node sysctl -w fs.inotify.max_user_instances=1024
  docker exec $node sysctl -w fs.inotify.max_user_watches=1048576
  docker exec $node apt update
  docker exec $node apt install -y tcpdump
done
