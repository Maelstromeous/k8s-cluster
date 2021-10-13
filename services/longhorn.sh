#!/usr/bin/env bash
# Sets up Longhorn disk storage provider.
# Usage: ./longhorn.sh

# Install Deps
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo apt-get install -y jq open-iscsi nfs-common