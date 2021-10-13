#!/usr/bin/env bash
# Starts the rancher control panel where you're able to access and manage clusters. The host that runs this needs pretty open internet access due to LetsEncrypt http challenges.
# Usage: ./rancherMasterSetup.sh <cluster.domain.com>

docker run -d --name rancher \
  --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  -v /opt/rancher:/var/lib/rancher \
  --privileged \
  rancher/rancher:latest \
  --acme-domain $1
