#!/usr/bin/env bash
# This file is required to be run *first* whether it's a master or a node.
# Usage: ./requiredSetup.sh

sudo curl https://releases.rancher.com/install-docker/20.10.sh | sh

sudo groupadd docker
sudo usermod -aG docker $USER
sudo newgrp docker

# And update the OS for good measure
sudo apt update && sudo apt upgrade -y

echo "Required setup steps complete. If you wish to run docker commands, please re-source or execute 'bash' to re-source that way."