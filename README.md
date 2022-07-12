# What's inside this repo

This repo contains terraform configuration files for provisioning a set of EC2 instances and other relevant resources which can be configured with the ansible scripts of the current repository to make a Kubernetes cluster. That is, the repo consists of the:

* Terraform configuration files which can be found in [provision_infra](/georgios_serafeim/kubernetes-kubeadm-aws-ec2/src/master/provision_infra/) folder and are responsible for provisioning the virtual infrastructure on AWS

* Ansible scripts which can be found in [configure_infra](/georgios_serafeim/kubernetes-kubeadm-aws-ec2/src/master/configure_infra/) folder and are responsible for installing Kubernetes on the EC2 instances using kubeadm

It's up to you whether you run the Ansible scripts or install kubernetes manually. In case you want to go with the manual installation, you can find the relevant instructions here: [Installation of kubernetes with kubeadm](assets/documents/install_k8s_with_kubeadm.md).

**Note: The virtual infrastructure provisioned by the configuration files of this repository, is intended to be used ONLY for training purposes!**

# Prerequisites for working with the repo<a name="prerequisites"></a>

* Your local machine, has to have terraform installed so you can run the terraform configuration files included in this repository. This repo has been tested with terraform 1.2.4
* Since Ansible is used for the configuration of the EC2 instances (i.e. for installing kubernetes with kubeadm), you also need to have Ansible installed on your local machine which will play the role of an Ansible control node. This repo has been tested with Ansible 2.13.1
* You need to use AWS console (prior to running the terraform configuration files) to generate a key-pair whose name you need to specify in the ``provision_infra/terraform.tfvars`` file (variable name is ```key_name```)
* You need to generate a pair of aws_access_key_id-aws_secret_access_key for you user on AWS using the console of AWS and provide the path where the credentials are stored to the variable called ```credentials_location``` which is in ```/provision_infra/terraform.tfvars``` file
* Go through the section [Accessing the EC2 instances](#access_instances) and make sure that you have [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), as well as [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and the proper configuration in ```~/.ssh/config``` and ```~/.aws/config``` files. 

# Accessing the EC2 instances<a name="access_instances"></a>

Access to the EC2 instances is needed both for humans and Ansible (which is used to install the kubernetes cluster). Although the AWS security groups where the instances are placed do **not** include any ingress rule to allow SSH traffic (port 22); using SSH to connect to them is still possible thanks to AWS Systems Manager. Terraform installs SSM Agent on the instances. 

### Human Access<a name="human_access"></a>
In order for a client (e.g. you local machine) to interact with them it needs to fullfil the below:

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
The ```USER_NAME``` of the kubernetes related nodes (i.e.: master node and worker nodes) is ```ubuntu```. The USER_NAME of the nginx server is ```ec2-user```. The ```KEY_PEM_FILE``` is the path pointing to the pem file of the key-pair that you need to generate as discussed in the [Prerequisites for working with the repo](#prerequisites) section.

### Ansible Access
When Ansible does not find an ```ansible.cfg``` file, it uses the defaults which means that it will use the configuration of ```~/.ssh/config``` for connecting via SSH to the hosts which needs to interact with. From that perspective, in order for Ansible to connect to the EC2 instances via SSH, all the points discussed in the section above ([Human Access](#human_access)) are still relevant. The playbooks themselves define the user that needs to be used, however, you still need to specify the ```KEY_PEM_FILE``` which is the pem file of the key-pair that you need to generate using AWS console as discussed in the [Prerequisites for working with the repo](#prerequisites) section.
For running the playbook of this repository follow the instructions in the section below: [Run Ansible](#run_ansible)


# Architecture

A high level view of the virtual infrastructure which will be created by the terraform configuration files included in this repo can be seen in the picture below: 

 ![High Level Setup](/assets/images/high_level_view.png)

#### Notes
* Subnet 10.0.1.0/24 is private in the sense that instances that are created inside it do not get a public IP
* Subnet 10.0.2.0/24 is public in the sense that instances which are created inside it get a public and a private IP
* All the nodes related to the kubernetes cluster (represented with green boxes) are located inside the private subnet
* Two route tables are created: one associated to the public subnet and one associated to the private subnet
* The default route of the private subnet is the NAT gateway which resides in the public subnet 
* The default route of the public subnet is the Internet Gateway (IGW)
* The master node of the kubernetes cluster and the worker nodes are in two different security groups which allow all the icmp traffic and the traffic that a kubernetes cluster generates to operate: ([ports and protocols used by Kubernetes components](https://kubernetes.io/docs/reference/ports-and-protocols/))
* No configuration is applied to AWS's default Network ACL which comes when creating the VPC which means that it does not block any traffic.

# Provision and configure the infrastructure

Note that terraform generates a file into [kubernetes-kubeadm-aws-ec2/configure_infra](/georgios_serafeim/kubernetes-kubeadm-aws-ec2/src/master/configure_infra/) which will be used as the inventory for Ansible

### Run terraform
In the folder [provision_infra](/georgios_serafeim/kubernetes-kubeadm-aws-ec2/src/master/provision_infra/) run:
```terraform apply```

### Run Ansible<a name="run_ansible"></a>
In the folder [configure_infra](/georgios_serafeim/kubernetes-kubeadm-aws-ec2/src/master/configure_infra/) run:
```ansible-playbook --private-key <KEY_PEM_FILE> -i inventory kubernetes_cluster.yml```