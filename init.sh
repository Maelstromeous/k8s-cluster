#!/usr/bin/env bash
# This file is required to be run *first* whether it's a master or a node.
# Usage: ./requiredSetup.sh

sudo curl https://releases.rancher.com/install-docker/20.10.sh | sh

# Longhorn disk manager setup
./services/longhorn.sh