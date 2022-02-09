# k8s-cluster
Configuration and associated scripts to provision a Rancher cluster.

This setup assumes you are using ubuntu boxes. PRs are welcome for other OSes. 

**Disclaimer**: all the below comes as-is, if you break your VPS / cluster with the below commands, that's on you.

# My setup & context

For context, my setup is a number of nodes running Ubuntu 20.X from a VPS provider called [Contabo](https://contabo.com). They have quite powerful yet very cheap VPS', starting with 4vCPUs and 8GB RAM with 200GB SSD / 50GB NVME for €4.99 (ex vat) a month (if you're on a month rolling you'll get a setup fee though!). What's the catch you might ask - because I thought that as well! Apparently they use slightly older generation CPUs, so don't expect a good return if your app is massively CPU heavy and requires top notch clock speeds. Contabo also wouldn't divulge what the CPUs they use, all they said was "We use Intel and AMD CPUs in the x86 instruction set", so no ARM here *yet*. My workloads are mostly RAM hungry, so the cheap price fits perfectly in my use case.

Additionally, I am using Rancher 2.5.x. I had a ton of issues on Rancher 2.6, at the time of writing it's simply too new and I was unable to fix issues such as stuck provisioning nodes etc as you couldn't edit the cluster.yml

# Cluster Config

Below are the steps to set up the cluster assuming you have bought your VPS' and have attained SSH access to each machine.

## First time setup for every node

For easy-peasy setup, copy pasta and run the following command as soon as you have access to your VPS:

```sudo apt update && sudo apt upgrade -y && sudo apt install -y git && git clone https://github.com/Maelstromeous/k8s-cluster.git && cd ~/k8s-cluster && ./init.sh```

## Rancher Runner setup

Rancher requires a singular master in order to perform cluster administration and in general manage the cluster. This role does a lot of stuff, so if possible it's recommended to have the master installed on a decently specced machine (2 cores, 4GB+ RAM) and is always powered on as it will contain the cluster's control plane.

`./rancherMasterSetup <cluster.domain.com>`

`<cluster.domain.com>` is the FQDN used for the purposes of having a self signed LetsEncrypt certificate so you don't have to worry about SSL! :tada:

Visit `<cluster.domain.com>` in your browser, go through the setup steps then add your own cluster! When you go to create one however, ensure you choose Custom cluster. It also has to be RKE1 (RK2 is in tech preview and is currently targeted for the government sector).

## Creating the cluster

1) Create a new cluster
2) Private Registry (if you're using private dockerhub images)
   1) Enabled
   2) URL: empty
   3) User: dockerhub username
   4) Pass: dockerhub password
3) Advanced:
   1) Nginx Default Backend: yes
   2) Pod Security Policy Support
      1) Default: unrestricted
   4) Docker version - Require supported
   5) etc snapshot backup target
      1) Fill out info, s3 region is `s3.eu-west-2.amazonaws.com
   6) Recurring etcd snapshot interval: 3 hours
   7) keep the last 16 (2 days worth)
   8) Maximum worker nodes unavailable: 2
   9) Drain nodes: yes
      1) Force: yes
4) Authorised cluster endpoint: <cluster.fqdn.com>

For the first node you're creating, you're **highly** recommended to only add etcd and control plane and *not* worker. reason being, is you have to faff about removing the worker role later. It's also recommended practice by Rancher.

## Node setup

Run the first time setup command, then go back to the cluster UI and run the command it gives you for Registering new nodes. If you lose your place, you can get back to the registration menu by clicking on the 3 lines, Cluster Management, click on your cluster, then Registration.

# Connecting to the cluster

Congrats! The cluster is now ready and installed! Now lets connect to this cluster shall we?

## kubectl

1. On your **local terminal to your machine** install `kubectl`. [Install steps](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
2. In **rancher's management UI** download the kubeconfig file, there's a button top right.

Now you have two options:

1. **If you have already got a docker cluster** then you need to inject various parts of the file you just downloaded into it.
2. **If you do not have a cluster** then simply move the downloaded file to a file named `~/.kube/config`

After you have done this, you should be able to swap to the cluster using `kubectl config use-context <CONTEXT NAME>`

Now all `kubectl` commands will pipe to your new cluster. Try it! Run `kubectl get pods -A` and it should spit out a long list of pods named like `canal` and `coredns` etc.

# Post installation steps & Recommended Tools

Below are the tools provided by Rancher which you should install.

* [Backups](#Backups)
* [Longhorn](#Longhorn)
* [Monitoring](#Monitoring)

## Backups

Do this. **Now.** Take it from me, you absolutely should. For example, I had a bad node which took down etcd, and it corrupted my entire cluster, even though I have etc backups things got so corrupt I couldn't recover. I had to make the entire cluster *again*.

To set this up, do:

1) Go to the local cluster
2) Create a new opaque secret called `aws-secret` and fill out the following k:v:
   1) `accessKey`: `Your AWS Key ID`
   2) `secretKey`: `Your Secret Key`
3) Go to Cluster Tools
4) Install Rancher Backup
5) Set up the default location being an S3 bucket and use the secret. Make sure to set up the endpoint correctly. e.g. `s3.eu-west-2.amazonaws.com`
6) **Ensure** that you create a recurring backup or you will have achieved nothing.
7) You should create at one off test backup to verify the objects land in S3.
8) Recommended schedule:
   1) daily-backup: `30 6 * * *` (daily backup 6:30am) 7 day retention
   2) hourly-backup `0 */1 * * *` (hourly backup at top of the hour) 48 hour retention

## Docker Hub Authentication

If like me you use Dockerhub to host all your application builds, you will need to add a credential to enable access to it. In order to do this you need to create a secret and register it with the cluster.

As of v2.6 the process for this has become super confusing. For me, the following worked:

1) Go to navigation tray and go to "Cluster Management"
2) Find your cluster and click on it's name
3) Go to config
4) Find "Private registry"
5) Add the following:
   1) URL: NONE (leave blank)
   2) Username: Your dockerhub username
   3) Password: Your dockerhub password
6) Scroll to the bottom and save

The cluster will re-provision and will take a few minutes. After this, you should be able to pull from your private docker repositories.

## Longhorn

Longhorn is a distributed block storage manager, which enables your cluster to create storage volumes. Normally a cloud operator would handle this via Persistent Volume Claims, and spin up say an EBS Volume (in AWS) or say a Digital Ocean Volume attached to the node it's requested on. This will create a PVC file type called "Longhorn", enabling your apps to persist data.

If you use the init.sh script, the dependencies are already installed.

Assuming you have set up your `kubectl` correctly, now run 

`curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.1.0/scripts/environment_check.sh | bash`

 on your **local** terminal. This runs a check to ensure you can use Longhorn. It should spit out `MountPropagation is enabled!`. If you get this, you're good to go.

### Installing

Go here to install Longhorn:

`Cluster -> Select Cluster -> Apps & Marketplace -> Search for Longhorn -> Install`

**NOTE** While Longhorn also shows up in the `Cluster Tools` bottom left, it didn't work for me that way.

### Configure Longhorn

In order to actually use Longhorn, you need to configure it. It is **highly** recommended you give the [Rancher Longhorn Docs](https://rancher.com/docs/rancher/v2.6/en/longhorn/) a good read first. We have already fufilled the installation requirements.

### Longhorn Config

You should now see a new option called `Longhorn` in the left hand menu. Clicking it will send you to the Longhorn Dashboard.

**I highly encourage you set up an S3 backup for your data!** [Instructions here](https://longhorn.io/docs/1.0.2/snapshots-and-backups/backup-and-restore/set-backup-target/)

You will need to create a secret of your AWS creds for backups. To do this, go to your AWS account and get an IAM ID and secret. Use the below commands to generate the secret

```
echo -n '<AWS_ACCESS_KEY_ID>' > ./key.txt
echo -n '<AWS_SECRET_ACCESS_KEY> > './secret.txt

kubectl create secret generic -n longhorn-system aws-secret \
--from-file=AWS_ACCESS_KEY_ID=./key.txt \
--from-file=AWS_SECRET_ACCESS_KEY=./secret.txt
```

Supply the name of your secret to the Longhorn settings.

You will also need to create a recurring Backup job or none of your data will be backed up!

## Monitoring

You're **highly** recommended installing the Rancher monitoring suite. This has built in monitoring and graphing tools for use with your cluster to enable you to diagnose issues and see the overall performance of it.

You should install Longhorn **first** as you'll be able to persist the statistics via a Longhorn PVC, so they don't get lost should a node or two die.

### Settings - Prometheus

* Enable persistence, select Longhorn storage class, ReadWriteMany.

### Settings - Grafana

When you are installing it, on step 2 ensure edit the Grafana settings and add:

* Enable with PVC Template
* Size 10G (probably doesn't need this much but you never know)
* Storage Class: Longhorn
* ReadWriteMany

Be patient with this install, it takes a while.

## You're done!

Now you've done all that, you can actually deploy your services! Check out [Deploying your services](deploying-services.md).
