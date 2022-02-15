# Deploying your services

If you've followed the instructions as they are in README.md, then you should be good to go!

## Setting up Ingress

Firstly, we need to manage ingress into our cluster. This will be done by using the default built in nginx ingress controller provided by Rancher. What we need to add to the cluster is a Lets Encrypt Certificate provisioner (which automatically registers and maintains certificates :tada:) and other things.

## Installing Cert Manager

Thankfully, we are able to leverage Helm to help us do this. You need at least version 3.3 installed.

1) Installation: https://cert-manager.io/docs/installation/helm/
2) Configuration (we're going to use ACME): https://cert-manager.io/docs/configuration/acme/
   1) To save some time, I've done this for you, open `/services/cert-manager-acme.yaml` and change your email address
   2) and run `kubectl apply -f services/cert-manager-acme.yaml`.

What this will do is create two LetsEncrypt cluster-wide certificate issuers (one staging for testing, one production / live which has rate limits), which we can use across the cluster despite namespace.

We are using [HTTP Validation](https://cert-manager.io/docs/tutorials/acme/http-validation/) here, where the cluster will configure the nginx ingress to enable LE to talk to us and verify we're the owners of the domain.

## Deploying a hello world app

Now open `samples/hello-world.yaml`. This contains a hello world application created by NGINX which spits out the IP of the host (in this case, it will be the Pod's IP) and it will create 3 copies of said pod.

To make it work, change `<YOUR HOSTNAME>` to a hostname that you have available, e.g. `helloworld.foo.com`. Your DNS for the A record **must point to a worker**, NOT your control plane instance (that got me scratching my head for hours). You are recommended to point the A record to each worker IP you have to attempt to load balance. DNS based load balancing doesn't work how you may think it does... it's randomly served and once it's served to a client it's cached and will continue to use that IP. Keep that in mind.

This file contains:

1) A persistent volume claim. This is the way you request disk space from the cluster. Note here we're using Longhorn, which is what we set up in the cluster to provision disks. Also note here we've got the `ReadWriteMany` type, which enables multiple pods to write to the same disk.
2) A deployment - this maintains 3 number of replica pods. The volume is mounted at this level and that's then distributed to the rest of the pods.
3) A service - this enables the ingresses to hit this service and that of which then loadbalances to the pods.
4) An ingress - this enables the nginx ingress controller which is installed by Rancher by default and instructs it on what to do and where to direct traffic. In this case, it's routing all traffic hitting your host to the service as defined above.
5) Finally, a certificate. This is configured to use the *production* issuer in the file, so if you're not fully confident with it yet change `letsencrypt` to `letsencrypt-staging` in the issuer reference. This resource will then spawn a `challenge` and attempt to authenticate your hostname by hitting it. It's a bit magic, and is out of the scope of this tutorial. If your cert isn't getting provisioned, hop onto rancher and try to find the resource, it tells you why it's failing (e.g. got a 403 code instead of 200 etc).

Once you have registered a domain name and changed the file, simply run `kubectl apply -f samples/hello-world.yaml` and after a minute or so the app should be fully loaded and responding in your browser, with HTTPS and a fully signed cert, on your domain. Keep refreshing the page and it should change the reported IP / hostname each time.

Congrats, you have now just deployed a fully working application! :tada:

## Deploying using GitHub actions

So I use GitHub actions for my projects to build and deploy the applications I develop. Below I will go over setup of how to use GHA to deploy your applications. Hopefully you will be able to figure out what you need for your CI solutions based off this.

1) Go to the Cluster Manager
2) Go to Global -> Security
3) Create a new user for CI `<CLUSTER URL>/g/security/accounts/add`
4) Go to your cluster, then `members`
5) Add your new user to members, give them member access
6) Go to your cluster then Projects/Namespaces
7) Find your Default project then click on the 3 dots, edit
8) Add your user as a member to the project as a Project Member
9) **IMPORTANT**: Add the new namespace of your application now (e.g. `hello-world-app`). 
   1) The user you cannot make its own namespaces due to RBAC (since it's purposefully **not** cluster administrator, it has no rights to). Once the namespace is made, it can do anything within it.
10) Log out of your admin user and into this new user
11) Go to your cluster and download the kubeconfig file

Now you might be thinking "wtf, why does GitHub need the kubeconfig?!", what we're doing here is enabling Kubectl the ability to control the cluster from GitHub actions. This enables us to fully use the kubectl application to manipulate our workloads.

Add the code found in `.github/workflows/workflow.yml` to your own repo and adjust it as required, e.g. repository URL. This will show you a real life example of the application. You can find this application hopefully still running on [hello.mattcavanagh.me](hello.mattcavanagh.me).

You will need to add the following secrets to your repository to make this work:

* `KUBE_CONFIG`: You need to supply a **base64 encoded output** of the kubeconfig file you have just downloaded.
* `DOCKERHUB_USERNAME`: username of your dockerhub account
* `DOCKERHUB_TOKEN`: a token you have generated for Dockerhub

After all that is done, push to your `main` branch, your workflow should work.

To see a real life example output of the GitHub actions (and see me failing 11 times before I got it working), [visit the GitHub actions repo of this project](https://github.com/Maelstromeous/k8s-cluster/actions).
