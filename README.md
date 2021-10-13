# k8s-cluster
Configuration and associated scripts to provision a Rancher cluster.

This setup assumes you are using ubuntu boxes. PRs are welcome for other OSes. 

**Disclaimer**: all the below comes as-is, if you break your VPS / cluster with the below commands, that's on you.

# My setup & context

For context, my setup is a number of nodes running Ubuntu 20.X from a VPS provider called [Contabo](https://contabo.com). They have quite powerful yet very cheap VPS', starting with 4vCPUs and 8GB RAM with 200GB SSD / 50GB NVME for €4.99 (ex vat) a month (if you're on a month rolling you'll get a setup fee though!). What's the catch you might ask - because I thought that as well! Apparently they use slightly older generation CPUs, so don't expect a good return if your app is massively CPU heavy and requires top notch clock speeds. Contabo also wouldn't divulge what the CPUs they use, all they said was "We use Intel and AMD CPUs in the x86 instruction set", so no ARM here *yet*. My workloads are mostly RAM hungry, so the cheap price fits perfectly in my use case.


# Cluster Config

Below are the steps to set up the cluster assuming you have bought your VPS' and have attained SSH access to each machine.

## First time setup

For easy-peasy setup, copy pasta and run the following command as soon as you have access to your VPS:

```sudo apt update && sudo apt upgrade -y && sudo apt install git && git clone https://github.com/Maelstromeous/k8s-cluster.git && cd ~/k8s-cluster && ./init.sh```

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

# Connecting to the cluster

Congrats! The cluster is now ready and installed! Now lets connect to this cluster shall we?

## kubectl

1. On your **local terminal to your machine** install `kubectl`. [Install steps](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
2. In **rancher's management UI** download the kubeconfig file, there's a button top right.

Now you have two options:

1. **If you have already got a docker cluster** then you need to inject various parts of the file you just downloaded into it.
2. **If you do not have a cluster** then simply move the downloaded file to a file named `~/.kube/config`

After you have done this, you should be able to swap to the cluster using `kubectl config use-context <CONTEXT NAME>`

Now all `kubectl` commands will pipe to your new cluster. Try it! Run `kubectl get pods -a` and it should spit out a long list of pods named like `canal` and `coredns` etc.

# Recommended cluster tools

Below are the tools provided by Rancher which you should install.


## Longhorn

Longhorn is the way your cluster manages it storage volumes. Normally a cloud operator would handle this via Persistent Volume Claims, and spin up say an EBS Volume (in AWS) or say a Digital Ocean Volume attached to the node it's requested on.

If you use the init.sh script, the dependencies are already installed.

Assuming you have set up your `kubectl` correctly, now run 

`curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.1.0/scripts/environment_check.sh | bash`

 on your **local** terminal. This runs a check to ensure you can use Longhorn. It should spit out `MountPropagation is enabled!`. If you get this, you're good to go.

### Configure cluster

In order to actually use Longhorn, you need to configure it. It is **highly** recommended you give the [Rancher Longhorn Docs](https://rancher.com/docs/rancher/v2.6/en/longhorn/) a good read first. We have already fufilled the installation requirements.

Go here to install Longhorn:

`Cluster -> Select Cluster -> Apps & Marketplace -> Search for Longhorn -> Install`

**NOTE** While Longhorn also shows up in the `Cluster Tools` bottom right, it didn't work for me that way.

### Longhorn Config

You should now see a new option called `Longhorn` in the left hand menu. Clicking it will send you to the Longhorn Dashboard.

**I highly encourage you set up an S3 backup for your data!** [Instructions here](https://longhorn.io/docs/1.0.2/snapshots-and-backups/backup-and-restore/set-backup-target/)

To enter the above settings, you need to find the Options section `Longhorn Default Settings` while you're installing Longhorn. Check the Customize Default Settings and add the backup target `s3://<your-bucket-name>@<your-aws-region>/`. 

You will need to create a secret of your AWS creds. To do this, go to your AWS account and get an IAM ID and secret. Use the below commands to generate the secret

```
echo -n '<AWS_ACCESS_KEY_ID>' > ./key.txt
echo -n '<AWS_SECRET_ACCESS_KEY> > './secret.txt

kubectl create secret generic -n longhorn-system aws-secret \
--from-file=AWS_ACCESS_KEY_ID=./key.txt \
--from-file=AWS_SECRET_ACCESS_KEY=./secret.txt
```

Supply the name of your secret to the Longhorn settings.

You will also need to create a recurring Backup job or none of your data will be backed up!