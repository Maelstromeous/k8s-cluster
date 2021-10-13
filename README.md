# k8s-cluster
Configuration and associated scripts to provision a Rancher cluster.

This setup assumes you are using ubuntu boxes. PRs are welcome for other OSes.

# My setup & context

For context, my setup is a number of nodes running Ubuntu 20.X from a VPS provider called [Contabo](https://contabo.com). They have quite powerful yet very cheap VPS', starting with 4vCPUs and 8GB RAM with 200GB SSD / 50GB NVME for €4.99 (ex vat) a month (if you're on a month rolling you'll get a setup fee though!). What's the catch you might ask - because I thought that as well! Apparently they use slightly older generation CPUs, so don't expect a good return if your app is massively CPU heavy and requires top notch clock speeds. Contabo also wouldn't divulge what the CPUs they use, all they said was "We use Intel and AMD CPUs in the x86 instruction set", so no ARM here *yet*. My workloads are mostly RAM hungry, so the cheap price fits perfectly in my use case.


# Cluster Config

Below are the steps to set up the cluster assuming you have bought your VPS' and have attained SSH access to each machine.

## First time setup

For easy-peasy setup, copy pasta and run the following command as soon as you have access to your VPS:

`sudo apt update && sudo apt upgrade -y && sudo apt install git && git clone https://github.com/Maelstromeous/k8s-cluster.git && cd k8s-cluster && ./init.sh`

## Master setup

Rancher requires a singular master in order to perform cluster administration and in general manage the cluster. This role does a lot of stuff, so if possible it's recommended to have the master installed on a decently specced machine (2 cores, 4GB+ RAM) and is always powered on as it will contain the cluster's control plane.

`./rancherMasterSetup <cluster.domain.com>`

`<cluster.domain.com>` is the FQDN used for the purposes of having a self signed LetsEncrypt certificate so you don't have to worry about SSL! :tada:

Visit cluster.domain.com in your browser, go through the setup steps then add your own cluster!

## Node setup

Once the cluster has been created in the UI of rancher, you will be prompted to add nodes to the cluster.

Grab the token from the UI that it provides you and run the command:

`./rancherNodeSetup.sh <cluster.domain.com> <TOKEN>`

This will then add your node to the cluster and perform some other best practice stuff.