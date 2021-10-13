#!/usr/bin/env bash
# This file is required to be run *first* whether it's a master or a node.
# Usage: ./requiredSetup.sh

curl https://releases.rancher.com/install-docker/20.10.sh | sh

groupadd docker
usermod -aG docker $USER
newgrp docker

# And update the OS for good measure
apt update && apt upgrade -y

echo "Required setup steps complete. If you wish to run docker commands, please re-source or execute 'bash' to re-source that way."