#!/usr/bin/env bash
# Adds the node to the cluster. You get the token from the cluster manager in rancher.
# Usage: ./rancherNodeSetup <cluster.domain.com> <TOKEN>

docker run -d --privileged --name k8s-node \
  --restart=unless-stopped \
  --net=host \
  -v /etc/kubernetes:/etc/kubernetes \
  -v /var/run:/var/run \
  rancher/rancher-agent:v2.6.1 --server https://$1 --token $2 --worker