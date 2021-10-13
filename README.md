# k8s-cluster
Configuration and associated scripts to provision a Rancher cluster.

This setup assumes you are using ubuntu boxes. PRs are welcome for other OSes.

# First time setup

`./firstSetup.sh`

Installs docker and updates the OS ready for rancher, either in master or worker mode.

# Master setup

Rancher requires a singular master in order to perform cluster administration and in general manage the cluster. This role does a lot of stuff, so if possible it's recommended to have the master installed on a decently specced machine (2 cores, 4GB+ RAM) and is always powered on as it will contain the cluster's control plane.

`./rancherMasterSetup <cluster.domain.com>`

`<cluster.domain.com>` is the FQDN used for the purposes of having a self signed LetsEncrypt certificate so you don't have to worry about SSL! :tada:

Visit cluster.domain.com in your browser, go through the setup steps then add your own cluster!

# Node setup

Once the cluster has been created in the UI of rancher, you will be prompted to add nodes to the cluster.

Grab the token from the UI that it provides you and run the command:

`./rancherNodeSetup.sh <cluster.domain.com> <TOKEN>`

This will then add your node to the cluster and perform some other best practice stuff.