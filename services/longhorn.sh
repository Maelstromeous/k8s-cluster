#!/usr/bin/env bash
# Sets up Longhorn disk storage provider.
# Usage: ./longhorn.sh

# Install Deps
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo apt-get install -y jq open-iscsi nfs-common

# Get GPG key for k8s google repo
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubectl

curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.1.0/scripts/environment_check.sh | bash