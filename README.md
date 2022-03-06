                              # k8s-cluster
Configuration and associated scripts to provision a Rancher cluster, as well as deploying a hello world application workload.

This setup assumes you are using ubuntu boxes. PRs are welcome for other OSes. 

**Disclaimer**: all the below comes as-is, if you break your VPS / cluster with the below commands, that's on you.

# My setup & context

For context, my setup is a number of nodes running Ubuntu 20.X from a VPS provider called [Contabo](https://contabo.com). They have quite powerful yet very cheap VPS', starting with 4vCPUs and 8GB RAM with 200GB SSD / 50GB NVMe for €4.99 (ex vat) a month (if you're on a month rolling you'll get a setup fee though!). What's the catch you might ask - because I thought that as well! Apparently they use slightly older generation CPUs, so don't expect a good return if your app is massively CPU heavy and requires top notch clock speeds. Also their support is rather... subpar in my experience. Contabo also wouldn't divulge what the CPUs they use, all they said was "We use Intel and AMD CPUs in the x86 instruction set", so no ARM here *yet*. My workloads are mostly RAM hungry, so the cheap price fits perfectly in my use case. Also Contabo's support is a bit slow in my experience, so you may be left in the lurch for a while.

## Rancher

I'm using [Rancher](https://rancher.com/why-rancher) 2.5.x. I had a ton of issues on Rancher 2.6, at the time of writing it's simply too new and I was unable to fix issues such as stuck provisioning nodes etc as you couldn't edit the cluster.yml

# Cluster Config

Below are the steps to set up the cluster assuming you have bought your VPS' and have attained SSH access to each machine.

## First time setup for every node

For easy-peasy setup, copy pasta and run the following command as soon as you have access to your VPS:

```sudo apt update && sudo apt upgrade -y && sudo apt install -y git && git clone https://github.com/Maelstromeous/k8s-cluster.git && cd ~/k8s-cluster && ./init.sh```

## Rancher Runner setup

Rancher requires a single master in order to perform cluster administration and in general manage the cluster, also known as the "Control Plane". This role does a lot of stuff, so if possible it's recommended to have the master installed on a decently specced machine (2 cores, 4GB+ RAM) and is always powered on as it will contain the cluster's control plane.

`./rancherMasterSetup <cluster.domain.com>`

`<cluster.domain.com>` is the FQDN used for the purposes of having a self signed LetsEncrypt certificate so you don't have to worry about SSL! :tada:

Visit `<cluster.domain.com>` in your browser, go through the setup steps then add your own cluster! When you go to create one however, ensure you choose Custom cluster. It also has to be RKE1 (RK2 is in tech preview and is currently targeted for the government sector).

## Creating the cluster

Select multi cluster mode (you'll be asked this only once).

Go to the very top and click on Global, then Add Cluster. Leave all options the default except:

1) Create a new cluster with "Existing Nodes" option
2) Name (obviously)
3) Private Registry (if you're using private dockerhub images - this is important if you're deploying your own apps to this that you don't want everyone and their dog to see your source code!):
   1) Enabled
   2) URL: empty / blank (if using dockerhub)
   3) User: dockerhub username
   4) Pass: dockerhub password
4) Advanced Options:
   1) Nginx Default Backend: yes
   2) Docker version: Require supported
   3) etc snapshot backup target:
      1) I assume you're competent enough to get your AWS access key etc. I recommend you IAM role permission scope it to Full Access by **bucket ARN** only.
      2) Choose S3
      3) Fill out info, s3 region endpoint is `s3.eu-west-2.amazonaws.com`
   4) Recurring etcd snapshot interval: 3 hours
   5) Keep the last 16 (2 days worth)
   6) Maximum worker nodes unavailable: 2 (adjust this to your liking)
   7) Drain nodes: yes
   8) Force: yes
5) Authorised cluster endpoint: <cluster.fqdn.com>
   1) The URL you give here **must** be registered with your DNS provider e.g. Cloudflare.

Once you have created the cluster, you will be presented with a screen that allows you to craft a command to execute on the node directly.

## Node provisioning

Run the [first time setup command](#first-time-setup-for-every-node) on each of your nodes if you haven't already, then go back to the cluster UI and run the command it gives you for Registering new nodes. There's a button to copy the command to clipboard.

For the first node you're creating, you're **highly** recommended to only add etcd and control plane and _not_ worker. reason being, is you have to faff about removing the worker role later. It's also recommended practice by Rancher.

Any subsequent nodes you add, make sure to change them to Worker. 

[Typical architecture](https://rancher.com/docs/rancher/v2.5/en/cluster-provisioning/production/recommended-architecture/) is:

* 1 Cluster Control Plane node (ideally 2+)
* 3+ etcd nodes
* Worker nodes to suit (you need at least 1 for the cluster to run)

In my setup I have nodes that perform both etcd and worker roles together. This isn't recommended practice however, but I've chosen to ignore that as I'm not made of money.

Once you've added your nodes, sit back, relax, grab a brew, and watch the cluster provision. 

# Connecting to the cluster

Congrats! The cluster is now ready and installed! Now let's connect to this cluster shall we?

## kubectl

1. On your **local terminal to your machine** install `kubectl`. [Install steps](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
2. To get the kubeconfig file, go to your cluster's dashboard (can get to it from the dropdown top left) and download the kubeconfig file, there's a button top right.

Now you have two options:

1. **If you have already got a kubernetes cluster** then you need to inject various parts of the file you just downloaded into it.
2. **If you do not have a cluster** then simply move / copy the downloaded file to a file named `~/.kube/config`

After you have done this, you should be able to swap to the cluster using `kubectl config use-context <CONTEXT NAME>`

Now all `kubectl` commands will pipe to your new cluster. Try it! Run `kubectl get pods -A` and it should spit out a long list of pods named like `canal` and `coredns` etc.

# Post installation steps & Recommended Tools

Below are the tools provided by Rancher which you should install.

* [Backups](#Backups)
* [Longhorn](#Longhorn)
* [Monitoring](#Monitoring)
* [Certificates](#Certificates)

## Backups

Do this. **Now.** Take it from me, you absolutely should. For example, I had a bad node which took down etcd, and it corrupted my entire cluster, even though I have etc backups things got so corrupt I couldn't recover. I had to make the entire cluster *again*.

To set this up, do:

1) Go to the local cluster
2) Create a new opaque secret called `aws-secret` and fill out the following key/values:
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

## Longhorn

Longhorn is a distributed block storage manager, which enables your cluster to create storage volumes. Normally a cloud operator would handle this via Persistent Volume Claims, and spin up say an EBS Volume (in AWS) or say a Digital Ocean Volume attached to the node it's requested on. This will create a PVC file type called "Longhorn", enabling your apps to persist data.

If you use the init.sh script, the dependencies are already installed.

Assuming you have set up your `kubectl` correctly, now run 

`curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.1.0/scripts/environment_check.sh | bash`

 on your **local** terminal. This runs a check to ensure you can use Longhorn. It should spit out `MountPropagation is enabled!`. If you get this, you're good to go.

### Installing

If you wish to use S3 backups, first apply a secret in the format:

Go here to install Longhorn:

`Cluster Explorer -> Top left, select Apps & Marketplace -> Charts -> Longhorn`

You can pretty much use all defaults, if you have a smaller 2 worker cluster change the default storage class to use 2 replicas instead of the default 3. Note this means you will only be able to have a single node failure tolerance.

### Configure Longhorn

In order to actually use Longhorn, you need to configure it. It is **highly** recommended you give the [Rancher Longhorn Docs](https://rancher.com/docs/rancher/v2.5/en/longhorn/) a good read first. We have already fufilled the installation requirements.

### Longhorn Config

You should now see a new option called `Longhorn` in the left hand menu. Clicking it will send you to the Longhorn Dashboard.

**I highly encourage you set up an S3 backup for your data!** [Instructions here](https://longhorn.io/docs/1.0.2/snapshots-and-backups/backup-and-restore/set-backup-target/)

#### Backup Settings
You will need to create a secret of your AWS creds for backups. To do this, go to your AWS account and get an IAM Key ID and secret.

After, you can go to Cluster Explorer, go to Secrets, and create a new opaque secret in the `longhorn-system` namespace. It must be there. In the following format:

```text
AWS_ACCESS_KEY_ID: <key>
AWS_SECRET_ACCESS_KEY: <secret>
```

Supply the name of your secret you just made to the Longhorn backup settings.

Also, for the S3 target, it must be un the format of: `s3://<your-bucket-name>@<your-aws-region>/mypath/` or it will error.

You will also need to create a recurring Backup job or none of your data will be backed up!

#### Replica Auto Balance

I turned this on to best-effort.

## Monitoring

You're **highly** recommended installing the Rancher monitoring application. This has built in monitoring and graphing tools for use with your cluster to enable you to diagnose issues and see the overall performance of it.

You should install Longhorn **first** as you'll be able to persist the statistics via a Longhorn PVC, so they don't get lost should a node or two die.

### Settings - Prometheus

* Enable persistence, select Longhorn storage class, ReadWriteMany. 30Gi seems reasonable for 10d retention. Don't forget to change the Retention setting to match.

### Settings - Grafana

When you are installing it, on step 2 ensure edit the Grafana settings and add:

* Enable with PVC Template
* Size 2Gi
* Storage Class: Longhorn
* ReadWriteMany

### FIXES TO PERFORM

**FIX #1:** There's a bug with the chart if you have Longhorn. You need to add the following to the values.yaml (click edit yaml)

```
grafana:
...
  initChownData:
    enabled: false
```

**FIX #2:** There's a bug with the chart where it attempts to add a malformed selector field for the persistent volume claim for `prometheus`. You need to remove the field entirely. Look for `selector: { matchExpressions: []`, or `storage: 40Gi`, should be under that. Delete the `selector` property entirely.

Be patient with this install, it takes a while.

## Certificates

I use cert-manager to provision and distribute certificates from LetsEncrypt. To install it, run:

1) `helm repo add jetstack https://charts.jetstack.io`
2) `kubectl create namespace cert-manager`
3) `kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.1/cert-manager.crds.yaml`

After this, the CRDs needed to provision certificates are now available, see `deploying-services.md` on their use.

## You're done!

Now you've done all that, you can actually deploy your services! Check out [Deploying your services](deploying-services.md).
