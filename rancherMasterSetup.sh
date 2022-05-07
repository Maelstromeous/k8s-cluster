#!/usr/bin/env bash
# Starts the rancher control panel where you're able to access and manage clusters. The host that runs this needs pretty open internet access due to LetsEncrypt http challenges.
# Usage: ./rancherMasterSetup.sh <cluster.domain.com>

sudo docker run -d --name rancher \
  --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  -v /opt/rancher:/var/lib/rancher \
  --privileged \
  rancher/rancher:v2.6.4 \
  --acme-domain $1

sudo docker logs -f rancher
