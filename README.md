# What's inside this repo

This repo contains terraform configuration files for provisioning a set of EC2 instances and other relevant resources which can be configured with the ansible scripts of the current repository to make a Kubernetes cluster. That is, the repo consists of the:
* Terraform configuration files which can be found in [provision_infra](/georgios_serafeim/kubernetes-kubeadm-aws-ec2/src/master/provision_infra/) folder and are responsible for provisioning the virtual infrastructure on AWS
* Ansible scripts which can be found in [configure_infra](/georgios_serafeim/kubernetes-kubeadm-aws-ec2/src/master/configure_infra/) folder and are responsible for installing Kubernetes on the EC2 instances using kubeadm

It's up to you whether you run the Ansible scripts or install kubernetes manually. In case you want to go with the manual installation, you can find the relevant instructions here: [Installation of kubernetes with kubeadm](/georgios_serafeim/kubernetes-kubeadm-aws-ec2/src/master/assets/documents/install_k8s_with_kubeadm.md).

**Note: The virtual infrastructure provisioned by the configuration files of this repository, is intended to be used ONLY for training purposes!**

# Prerequisites for working with the repo

* Your local machine, has to have terraform installed so you can run the terraform configuration files included in this repository. This repo has been tested with terraform 1.2.4
* Since Ansible is used for the configuration of the EC2 instances (i.e. for installing kubernetes with kubeadm), you also need to have Ansible installed on your local machine which will play the role of an Ansible control node. This repo has been tested with Ansible 2.13.1
* You need to use AWS console (prior to running the terraform configuration files) to generate a key-pair whose name you need to specify in the ``provision_infra/terraform.tfvars`` file (variable name is ```key_name```)
* You need to generate a pair of aws_access_key_id-aws_secret_access_key for you user on AWS using the console of AWS and provide the path where the credentials are stored to the variable called ```credentials_location``` which is in ```/provision_infra/terraform.tfvars``` file
* Go through the section [Accessing the EC2 instances](#Accessing the EC2 instances) and make sure that you have [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), as well as [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and the proper configuration in ```~/.ssh/config``` and ```~/.aws/config``` files. 

# Accessing the EC2 instances

Access to the EC2 instances is needed both for humans and Ansible (which is used to install the kubernetes cluster). Although the AWS security groups where the instances are placed do **not** include any ingress rule to allow SSH traffic (port 22); using SSH to connect to them is still possible thanks to AWS Systems Manager. Terraform installs SSM Agent on the instances. 

### Human Access
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
The ```USER_NAME``` of the kubernetes related nodes (i.e.: master node and worker nodes) is ```ubuntu```. The USER_NAME of the nginx server is ```ec2-user```. The ```KEY_PEM_FILE``` is the path pointing to the pem file of the key-pair that you need to generate as discussed in the [Prerequisites for working with the repo](#Prerequisites for working with the repo) section.

### Ansible Access
When Ansible does not find an ```ansible.cfg``` file, it uses the defaults which means that it will use the configuration of ```~/.ssh/config``` for connecting via SSH to the hosts which needs to interact with. From that perspective, in order for Ansible to connect to the EC2 instances via SSH, all the points discussed in the section above ([Human Access](###Human Access)) are still relevant. The playbooks themselves define the user that needs to be used, however, you still need to specify the ```KEY_PEM_FILE``` which is the pem file of the key-pair that you need to generate using AWS console as discussed in the [Prerequisites for working with the repo](#Prerequisites for working with the repo) section.
For running the playbook of this repository follow the instructions in the section below: [Run Ansible](###Run Ansible)


# Architecture

A high level view of the virtual infrastructure which will be created by the terraform configuration files included in this repo can be seen in the picture below: 

 ![High Level Setup](/assets/images/high_level_view.png)

#### Notes
* Subnet 10.0.1.0/24 is private in the sense that instances that are created inside it do not get a public IP
* Subnet 10.0.2.0/24 is public in the sense that instances which are created inside it get a public and a private IP
* All the nodes related to the kubernetes cluster are located inside the private subnet
* Two route tables are created: one associated to the public subnet and one associated to the private subnet
* The default route of the private subnet is the NAT gateway which resides in the public subnet 
* The default route of the public subnet is the Internet Gateway (IGW)
* The master node of the kubernetes cluster and the worker nodes are in two different security groups which allow all the icmp traffic and the traffic that a kubernetes cluster generates to operate: ([ports and protocols used by Kubernetes components](https://kubernetes.io/docs/reference/ports-and-protocols/))
* No configuration is applied to AWS's default Network ACL which comes when creating the VPC which means that it does not block any traffic.

# Provision and configure the infrastructure

### Run terraform

### Run Ansible
```ansible-playbook --private-key <KEY_PEM_FILE> -i inventory git-setup.yml```

# Installation of kubernetes with kubeadm

#### Perform all acctions in this section as root user

`sudo -i`
<br/><br/>

#### Letting iptables see bridged traffic (Perform the steps below in all nodes)


Make sure that the br_netfilter module is loaded. This can be done  by running:

`lsmod | grep br_netfilter`

If the br_netfilter module is not loaded, you can load it explicitly with: 

`sudo modprobe br_netfilter`

Set net.bridge.bridge-nf-call-iptables to 1:

```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 2
EOF
sudo sysctl --system
```
<br/><br/>
#### Docker installation (Perform the steps below in all nodes)

Update the apt package index and install packages to allow apt to use a repository over HTTPS:

`apt-get update`

`apt-get -y install ca-certificates curl gnupg lsb-release`


Add Docker's official GPG key:

`mkdir -p /etc/apt/keyrings`

`curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg`

Set up the repository:

`echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null`

Install Docker Engine:

`apt-get update`

`apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin`


Configure docker to start on boot:

`systemctl enable docker.service`

`systemctl enable containerd.service`
<br/><br/>
#### Install cri-dockerd (Perform the steps below in all nodes)

Install GO:

`wget https://storage.googleapis.com/golang/getgo/installer_linux`

`chmod +x ./installer_linux`

`./installer_linux`

`source /root/.bash_profile`

Clone the project code from the Github repository:

`git clone https://github.com/Mirantis/cri-dockerd.git`

Build the code:

`cd cri-dockerd`

`mkdir bin`

`go get && go build -o bin/cri-dockerd`

Install cri-dockerd: 

`mkdir -p /usr/local/bin`

`install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd`

`cp -a packaging/systemd/* /etc/systemd/system`

Start and enable the cri-docker service:

`sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service`

`systemctl daemon-reload`

`systemctl enable cri-docker.service`

`systemctl enable --now cri-docker.socket`

Check service status:

`systemctl status cri-docker.socket`
<br/><br/>
#### Installation of kubectl, kubeadm and kubelet (Perform the below in all nodes)

Update the apt package index and install packages needed to use the Kubernetes apt repository:  
`apt-get update`

`apt-get install -y apt-transport-https ca-certificates curl`

Download Google Cloud public signing key:  
`curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg`

Add the kubernetes apt repository:  
`echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list`

Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:  
`sudo apt-get update`

`sudo apt-get install -y kubelet kubeadm kubectl`

`sudo apt-mark hold kubelet kubeadm kubectl`
<br/><br/>
#### Initialize the control plane node (only on master node)

Before initializing the control plane node create a kubeadm-config.yaml file under /tmp with the following content:
<br/><br/>
```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: "unix:///var/run/cri-dockerd.sock"
localAPIEndpoint:
  advertiseAddress: "10.0.1.4"
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.24.2
networking:
  podSubnet: "10.244.0.0/16"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
```

Initialize kubeadm:    

`kubeadm init --config /tmp/kubeadm-config.yaml`


export kubeconfig:   

`export KUBECONFIG=/etc/kubernetes/admin.conf`
<br/><br/>
#### Deploy a pod network to the cluster (weavenet in this case) (only on master node)

`kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=1.24.2"`
<br/><br/>
#### Join the nodes (the command below should run on each WORKER node only)

`kubeadm join 10.0.1.4:6443 --token xw7a8g.djctcrs7q0hixvbe --discovery-token-ca-cert-hash sha256:15bc9b6e0342ce55f8537f9523c78c09e05749adf677432b5537d2a5abc1ea1d --cri-socket unix:///var/run/cri-dockerd.sock`






 
