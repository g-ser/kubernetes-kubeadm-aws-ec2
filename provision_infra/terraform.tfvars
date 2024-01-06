# credentials for connecting to AWS
credentials_location = "~/.aws/credentials"

# key for connecting to EC2 instances for managing them
key_name = "gs_key_pair"

# VPC
region         = "eu-central-1"
vpc_cidr_block = "10.0.0.0/16"

# subnets
private_subnet_cidr_block = "10.0.1.0/24"
public_subnet_cidr_block  = "10.0.2.0/24"

# master node
master_node_ip_address = "10.0.1.4"
# Canonical, Ubuntu, 22.04 LTS ami
master_node_ami = "ami-0faab6bdbac9486fb"
# t2.medium instance type covers kubeadm minimun 
# requirements for the master node which are 2 CPUS
# and 1700 MB memory
master_node_instance_type = "t3.small"

# worker nodes
worker_node01_ip_address = "10.0.1.5"
worker_node02_ip_address = "10.0.1.6"
# Canonical, Ubuntu, 22.04 LTS ami
worker_node_ami           = "ami-0faab6bdbac9486fb"
worker_node_instance_type = "t3.small"

# nginx server
# Amazon Linux 2 Kernel 5.10 ami
nginx_server_ami           = "ami-02da8ff11275b7907"
nginx_server_instance_type = "t3.micro"
