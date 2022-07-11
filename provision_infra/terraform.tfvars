# credentials for connecting to AWS
credentials_location = "~/.aws/credentials"

# key for connecting to EC2 instances for managing them
key_name = "main-key"

# VPC
region = "us-east-1"
vpc_cidr_block = "10.0.0.0/16" 

# subnets
private_subnet_cidr_block = "10.0.1.0/24"
public_subnet_cidr_block = "10.0.2.0/24"

# master node
master_node_ip_address = "10.0.1.4"
master_node_ami = "ami-052efd3df9dad4825"
# t2.medium instance type covers kubeadm minimun 
# requirements for the master node which are 2 CPUS
# and 1700 MB memory
master_node_instance_type = "t2.medium"

# worker nodes
worker_node01_ip_address = "10.0.1.5" 
worker_node02_ip_address = "10.0.1.6"
worker_node_ami = "ami-052efd3df9dad4825"
worker_node_instance_type = "t2.micro"

# nginx server
nginx_server_ami = "ami-0cff7528ff583bf9a"
nginx_server_instance_type = "t2.micro"

