# What's inside this repo

This repo contains terraform configuration files for provisioning a set of EC2 instances (and other relevant resources) which can be used later to install a kubernetes cluster using kubeadm.

At the moment, the terraform configuration files of this repo take care of setting up the EC2 instances on AWS and they do **NOT** install kubernetes.

After running terraform and having the EC2 related infrastructure in place, you can proceed installing kubernetes with kubeadm by following the steps described in the section of this file called [Installation of kubernetes with kubeadm](#Installation of kubernetes with kubeadm).

**Note: The virtual infrastructure provisioned by the configuration files of this repository, is intended to be used ONLY for training purposes!**

# Architecture

A high level view of the virtual infrastructure which will be created by the terraform configuration files included in this repo can be seen in the picture below:

 ![High Level Setup](/images/high_level_view.png)

#### Notes


# Run terraform

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


Add Docker’s official GPG key:

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






 
