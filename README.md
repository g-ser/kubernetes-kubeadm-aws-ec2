### What's inside this repo

This repo contains terraform configuration files for provisioning a set of EC2 instances (and other relevant resources) which can be used later to install a kubernetes cluster using kubeadm.

At the moment, the terraform configuration files of this repo take care of setting up the EC2 instances on AWS and they do **NOT** install kubernetes.

After running terraform and having the EC2 related infrastructure in place, you can proceed installing kubernetes with kubeadm by following the steps described in the section of this file called [Installation of kubernetes with kubeadm](#Installation of kubernetes with kubeadm).

**Note: The virtual infrastructure provisioned by the configuration files of this repository, is intended to be used ONLY for training purposes!**

### Architecture

A high level view of the virtual infrastructure which will be created by the terraform configuration files included in this repo can be seen in the picture below:

 ![High Level Setup](/images/high_level_view.png)

#### Notes


### Run terraform




### Installation of kubernetes with kubeadm








 
