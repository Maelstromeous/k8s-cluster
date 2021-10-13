#!/usr/bin/env bash
# Sets up Longhorn disk storage provider.
# Usage: ./longhorn.sh

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo apt-get install -y jq open-iscsi nfs-common

curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.1.0/scripts/environment_check.sh | bash