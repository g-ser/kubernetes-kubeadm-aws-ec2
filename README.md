# Motivation

The purpose of this repo is to provision quickly a kubernetes cluster on AWS which can be used for training on kubernetes (e.g. using kubectl commands). I built it during my studies for the CKA (Certified Kubernetes Administrator) certification. Since the cluster can be created within minutes, it is ideal for experimenting with kubernetes without being worried about breaking the cluster (if that happens, you just need to tear the cluster down (with terraform destroy) and provision it again).

# What's inside this repo<a name="repo_content"></a>

This repo contains terraform configuration files for provisioning a set of EC2 instances and other relevant resources which can be configured with the ansible scripts of the current repository to make a Kubernetes cluster. That is, the repo consists of:

* Terraform configuration files which can be found in [provision_infra](/provision_infra/) folder and are responsible for provisioning the virtual infrastructure on AWS

* Ansible scripts which can be found in [configure_infra](/configure_infra/) folder and are responsible for installing Kubernetes on the EC2 instances using kubeadm

It's up to you whether you run the Ansible scripts or install kubernetes manually. In case you want to go with the manual installation, you can find the relevant instructions here: [Installation of kubernetes with kubeadm](assets/documents/install_k8s_with_kubeadm.md).

If you run both the terraform configuration files and the ansible scripts (check [Provision and configure the infrastructure](#run_scripts) for instructions), they will create a kubernetes cluster for you which comprises the software components listed below:

* 3 EC2 AWS instances (1 master node & 2 worker nodes) running Ubuntu 22.04 LTS
* Each of the 3 nodes of the cluster will have docker installed as the container engine.  [Cri-dockerd](https://github.com/Mirantis/cri-dockerd) is also installed since kubernetes cannot integrate natively with docker any more, so cri-dockerd is needed to act as the middleman.
* The network plugin of the kubernetes cluster that is installed by the Ansible scripts is [weavenet](https://www.weave.works/docs/net/latest/overview/)
* Kubernetes version is 1.25.0. The version is controlled by the variable ```kubernetes_version``` in file [configure_infra/group_vars/all](configure_infra/group_vars/all). You can change the version in that file in case you want to install a new one, but keep in mind that the Ansible scripts were only tested with 1.25.0-00.
* A NAT gateway (check illustration of section [Architecture](#architecture)), which is responsible for allowing the nodes of the kubernetes cluster which are located in a private subnet to access services located in the Internet (e.g. for managing software packages using yum)
* A VM located in the public subnet with NGINX server installed, configured to act as a reserve proxy for exposing the applications running on the kubernetes cluster to the outside world (check section [Expose applications to the Internet](#expose_apps))  

**Note: The kubernetes infrastructure provisioned using the source code of this repository, is intended to be used ONLY for training purposes!**


# Prerequisites for working with the repo<a name="prerequisites"></a>

* Your local machine, has to have terraform installed so you can run the terraform configuration files included in this repository. This repo has been tested with terraform 1.2.4
* Since Ansible is used for the configuration of the EC2 instances (i.e. for installing kubernetes with kubeadm), you also need to have Ansible installed on your local machine which will play the role of an Ansible control node. This repo has been tested with Ansible 2.13.1
* You need to generate a pair of aws_access_key_id-aws_secret_access_key for your AWS user using the console of AWS and provide the path where the credentials are stored to the variable called ```credentials_location``` which is in ```/provision_infra/terraform.tfvars``` file. This is used by terraform to make programmatic calls to AWS.
* You need to use AWS console (prior to running the terraform configuration files) to generate a key-pair whose name you need to specify in the ``provision_infra/terraform.tfvars`` file (variable name is ```key_name```). The ```pem``` file (which has to be downloaded from AWS and stored on your local machine) of the key pair, is used in order for Ansible to authenticate when connecting to the EC2 instances with ssh.
* Go through the section [Accessing the EC2 instances](#access_instances) and make sure that you have [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), as well as [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and the proper configuration in ```~/.ssh/config``` and ```~/.aws/config``` files. 

# Accessing the EC2 instances<a name="access_instances"></a>

Access to the EC2 instances is needed both for humans and Ansible (which is used to install the kubernetes cluster). Although the AWS security groups where the instances are placed do **not** include any ingress rule to allow SSH traffic (port 22); using SSH to connect to them is still possible thanks to AWS Systems Manager. Terraform installs SSM Agent on the instances. 

### Human Access<a name="human_access"></a>
In order for a client (e.g. you local machine) to ssh to the EC2 instances, it needs to fullfil the below:

* Have AWS CLI installed: [Installation of AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* Have the Session Manager plugin for the AWS CLI installed: [Install the Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
* Have the configuration below into the SSH configuration file of your local machine (typically located at ```~/.ssh/config```)
<br/><br/>
```shell
# SSH over Session Manager
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```
<br/><br/>
* Specify in the ```~/.aws/config``` file the AWS region like below:
<br/><br/>
```shell
[default]
region=<AWS_REGION>
```
<br/><br/>
You can connect using the command: ```ssh -i <KEY_PEM_FILE> <USER_NAME>@<INSTANCE_ID>```
The ```USER_NAME``` of the kubernetes related nodes (i.e.: master node and worker nodes) is ```ubuntu```. The USER_NAME of the NGINX server is ```ec2-user```. The ```KEY_PEM_FILE``` is the path pointing to the pem file of the key-pair that you need to generate as discussed in the [Prerequisites for working with the repo](#prerequisites) section.
When terraform finishes its execution, it returns a bunch of outputs. Among those, you can find the instance id of the master node (```instance_id_master_node```), which you can use as follows to connect to the EC2 instace: ```ssh -i <KEY_PEM_FILE> ubuntu@<INSTANCE_ID_MASTER_NODE>```. Once you are connected as ```ubuntu``` user, you can switch to ```root``` with the command: ```sudo -i```. However, if you run the Ansible scripts of this repo, you should be able to run kubectl commands as the ```ubuntu``` user  


### Ansible Access
When Ansible does not find an ```ansible.cfg``` file, it uses the defaults which means that it will use the configuration of ```~/.ssh/config``` for connecting via SSH to the hosts which needs to interact with. From that perspective, in order for Ansible to connect to the EC2 instances via SSH, all the points discussed in the section above ([Human Access](#human_access)) are still relevant. The playbooks themselves define the user that needs to be used, however, you still need to specify the ```KEY_PEM_FILE``` which is the pem file of the key-pair that you need to generate using AWS console as discussed in the [Prerequisites for working with the repo](#prerequisites) section.
For running the playbook of this repository follow the instructions in the section below: [Run Ansible](#run_ansible)


# Architecture<a name="architecture"></a>

A high level view of the virtual infrastructure which will be created by the terraform configuration files included in this repo can be seen in the picture below: 

 ![High Level Setup](/assets/images/high_level_view.png)

#### Notes
* Subnet 10.0.1.0/24 is private in the sense that instances that are created inside it do not get a public IP
* Subnet 10.0.2.0/24 is public in the sense that instances which are created inside it get a public and a private IP
* All the nodes related to the kubernetes cluster (represented with green boxes) are located inside the private subnet
* Two route tables are created: one associated to the public subnet and one associated to the private subnet
* The default route of the private subnet is the NAT gateway which resides in the public subnet 
* The default route of the public subnet is the Internet Gateway (IGW)
* The master node of the kubernetes cluster and the worker nodes are in two different security groups:
    * both security groups allow traffic originating from the private subnet, that a kubernetes cluster generates to operate: ([ports and protocols used by Kubernetes components](https://kubernetes.io/docs/reference/ports-and-protocols/))
    * the security group where the worker nodes reside allows all icmp traffic originated from the private subnet
    * the security group where the master node resides allows all icmp traffic originated from the private and public subnets
    * both security groups allow traffic originating from the private subnet whose target is tcp port 6783 and udp ports 6783-6784. Since weavenet is used as the network plugin of the cluster, we need to open those ports due to the fact that weavenet uses them as control and data ports.
* No configuration is applied to AWS's default Network ACL which comes when creating the VPC which means that it does not block any traffic.

# Provision and configure the infrastructure<a name="run_scripts"></a>

Note that terraform generates a file into [kubernetes-kubeadm-aws-ec2/configure_infra](/configure_infra/) called ```inventory``` which will be used as the inventory for Ansible

### Run terraform
In the folder [provision_infra](/provision_infra/) run:
```terraform apply```

### Run Ansible<a name="run_ansible"></a>
In the folder [configure_infra](/configure_infra/) run:
```ansible-playbook --private-key <KEY_PEM_FILE> -i inventory kubernetes_cluster.yml```

# Expose applications to the Internet<a name="expose_apps"></a>

The ansible scripts of this repo install NGINX ingress controller with ```kubectl apply``` using YAML manifests. More specifically, the yaml file that is used is the [configure_infra/roles/ingress/templates/nginx-ingress-controller.yaml](configure_infra/roles/ingress/templates/nginx-ingress-controller.yaml) and it was taken from [here](https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/baremetal/deploy.yaml)

The ingress is made accessible outside the kubernetes cluster by being published as a node port (a better approach would be to publish it using an AWS load balancer but due to the fact that cloud native load balancers are costly and this infrastructure is meant to be used only for training purposes (i.e. for practicing with kubernetes), it was chosen to expose it using a node port). The node port used to expose the ingress is set to ```32451``` but it can be changed by modifying the variable ```ingress_exposed_node_port``` in file [configure_infra/group_vars/all](configure_infra/group_vars/all).

As written in the [first section](#repo_content) of the current documentation, ansible configures a VM (located in the public subnet), to act as a reverse proxy. This is done by having ansible installing NGINX and then configure it to act as a reverse proxy (check [here](configure_infra/roles/nginx_server/tasks/main.yml)). That is, whatever http traffic reaches the public IP of the nginx server (its public IP is part of terraform's outputs), it is forwarded to the NGINX controller inside the kubernetes cluster through the node port ```32451```. Do not confuse the NGINX ingress controller which is part of the kubernetes cluster (deployed in the namespace called ```ingress-nginx```) with the NGINX Linux VM which resides in the public subnet and is depicted in the picture of section [Architecture](#architecture) with purple colour.

After deploying the NGINX ingress controller, ansible proceeds with the creation of an ingress resource. In addition, it creates a deployment with a single web server pod to which all incoming traffic is forwarded through a service. This is done so you can use the web server application as a reference for exposing your own applications to the Internet. 

More specifically, the relevant kubernetes objects are: an ingress resource, a config map, a deployment and a service. The kubernetes definition file which includes the 4 objects can be found [here](configure_infra/roles/ingress/templates/ingress-resource.yaml). The service named httpd-service has the IP of the web server pod as its endpoint. The ingress resource has a single rule which routes all incoming traffic to the httpd-service. The web server pod of the deployment is mapped to the service using labels and selectors. Finally the config map is used to mount an index.html file that includes the message "Hello World" to the web server pod. When ansible terminates without errors, you should be able to see the "Hello World" message by accessing the public IP of the NGINX VM using your browser.  
