# This terraform script creates a k8s cluster on AWS using kubeadm 
# The cluster consists of a master node and two worker nodes
# All the nodes of the k8s cluster are placed in a custom VPC and more specifically 
# in the private subnet of the custom VPC (10.0.1.0/24)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.20.1"
    }
  }
}

# Configure the AWS Provider and credentials
provider "aws" {
  region     = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

# Create a VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "k8s_vpc"
  }
}

# Create private subnet
resource "aws_subnet" "k8s_private_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "k8s_private_subnet"
  }
}

# Create public subnet 
resource "aws_subnet" "k8s_public_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "k8s_public_subnet"
  }
}



# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.k8s_vpc.id
}

# Create a public route table for reaching the Internet
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Associate the public subnet to the public route table
resource "aws_route_table_association" "public_route_subnet_association" {
  subnet_id      = aws_subnet.k8s_public_subnet.id
  route_table_id = aws_route_table.public-route-table.id
}


# Create a private route table for the private subnet
resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    # the default route for the traffic originating 
    # from the private subnet goes to nat gateway 
    gateway_id = aws_nat_gateway.public_nat.id
  }

  tags = {
    Name = "private_route_table"
  }
}

# Associate the private subnet to the private route table
resource "aws_route_table_association" "private_route_subnet_association" {
  subnet_id      = aws_subnet.k8s_private_subnet.id
  route_table_id = aws_route_table.private-route-table.id
}

# Create a security group for the public subnet

resource "aws_security_group" "public" {
  name        = "allow_web_traffic"
  description = "Allow ssh & web traffic"
  vpc_id      = aws_vpc.k8s_vpc.id


   ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "public"
  }
}


# Create a security group for the EC2 instance 
# which will represent the master node.
# The interface of this instance will be associated to the 
# security group created here

resource "aws_security_group" "master_node" {
  name        = "allow_ctrl_plane_traffic"
  description = "Allow inbound traffic needed for k8s control plane to operate"
  vpc_id      = aws_vpc.k8s_vpc.id
  
  ingress {
    description      = "Allow all icmp traffic from the private subnet"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  ingress {
    description      = "Allow all icmp traffic from the public subnet"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = [aws_subnet.k8s_public_subnet.cidr_block]
  }

  ingress {
    description      = "HTTPS from public subnet"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_public_subnet.cidr_block]
  }

  ingress {
    description      = "HTTP from public subnet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_public_subnet.cidr_block]
  }

  ingress {
    description      = "Kubernetes API server"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  ingress {
    description      = "etcd server client API"
    from_port        = 2379
    to_port          = 2380
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  ingress {
    description      = "Kubelet API"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  ingress {
    description      = "kube-scheduler"
    from_port        = 10259
    to_port          = 10259
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  ingress {
    description      = "kube-controller-manager"
    from_port        = 10257
    to_port          = 10257
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ctrl_plane_traffic"
  }
}

# Create a security group for the EC2 instances 
# which will represent the worker nodes.
# The interface of those instances will be associated to the 
# security group created here


resource "aws_security_group" "worker_node" {
  name        = "allow_worker_nodes_traffic"
  description = "Allow inbound traffic needed for the worker nodes to operate"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description      = "Allow all icmp traffic"
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  ingress {
    description      = "Kubelet API"
    from_port        = 10250
    to_port          = 10250
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  ingress {
    description      = "NodePort Services"
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = [aws_subnet.k8s_private_subnet.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_worker_nodes_traffic"
  }
}

# Create network interfaces for the three EC2 instances
# which will be part of the k8s cluster
# The instance representing the master node 
# will be placed in the master node security group
# The instances representing the worker nodes
# will be placed in the worker node security group

resource "aws_network_interface" "master_node_iface" {
  subnet_id   = aws_subnet.k8s_private_subnet.id
  private_ips = ["10.0.1.4"]
  security_groups = [aws_security_group.master_node.id]
  tags = {
    Name = "master_node_iface"
  }
}

resource "aws_network_interface" "worker_node01_iface" {
  subnet_id   = aws_subnet.k8s_private_subnet.id
  private_ips = ["10.0.1.5"]
  security_groups = [aws_security_group.worker_node.id]
  tags = {
    Name = "worker_node01_iface"
  }
}

resource "aws_network_interface" "worker_node02_iface" {
  subnet_id   = aws_subnet.k8s_private_subnet.id
  private_ips = ["10.0.1.6"]
  security_groups = [aws_security_group.worker_node.id]
  tags = {
    Name = "worker_node02_iface"
  }
}



# create NAT gateway attached to the public subnet
# so all the instances located into the private subnet
# can reach the Internet
# This will be usefull for running commands like 
# apt-get upgrade/update on the instances located in the
# private subnet


#create an aws elastic ip for the NAT gateway
resource "aws_eip" "nat_gw_eip" {
  vpc      = true
  depends_on = [aws_internet_gateway.gw]
}

# create the NAT gateway
resource "aws_nat_gateway" "public_nat" {
  allocation_id = aws_eip.nat_gw_eip.id
  subnet_id     = aws_subnet.k8s_public_subnet.id
  connectivity_type = "public"
  tags = {
    Name = "nat_gw"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

# get the private ip of the nat gateway  
output "private_ip_nat_gw" {
  value = aws_nat_gateway.public_nat.private_ip
}

# Create 3 EC2 instances 
# Those will play the role of the nodes in the k8s cluster (2 worker nodes - 1 master node)
# They will all be placed into the private subnet

#create master node
resource "aws_instance" "k8s-master-node" {
  ami           = "ami-052efd3df9dad4825"
#   key_name= "main-key"
  network_interface {
    network_interface_id = aws_network_interface.master_node_iface.id
    device_index         = 0
  }
  # t2.medium instance type covers kubeadm minimun 
  # requirements for the master node which are 2 CPUS
  # and 1700 MB memory
  instance_type = "t2.medium"
  tags = {
    Name = "k8s-master-node"
  }
  user_data = "${data.cloudinit_config.master_node.rendered}"
  iam_instance_profile = aws_iam_instance_profile.ssm-iam-profile.name 
}

output "instance_id_master_node" {
  value = aws_instance.k8s-master-node.id
}

#create worker node01
resource "aws_instance" "k8s-worker-node01" {
  ami           = "ami-052efd3df9dad4825"
#   key_name= "main-key"
  network_interface {
    network_interface_id = aws_network_interface.worker_node01_iface.id
    device_index         = 0
  }
  instance_type = "t2.micro"
  tags = {
    Name = "k8s-worker-node01"
  }
  user_data = "${data.cloudinit_config.k8s-worker-node01.rendered}"
  iam_instance_profile = aws_iam_instance_profile.ssm-iam-profile.name 
}

output "instance_id_k8s_worker_node01" {
  value = aws_instance.k8s-worker-node01.id
}

#create worker node02
resource "aws_instance" "k8s-worker-node02" {
  ami           = "ami-052efd3df9dad4825"
#   key_name= "main-key"
  network_interface {
    network_interface_id = aws_network_interface.worker_node02_iface.id
    device_index         = 0
  }
  instance_type = "t2.micro"
  tags = {
    Name = "k8s-worker-node02"
  }
  user_data = "${data.cloudinit_config.k8s-worker-node02.rendered}"
  iam_instance_profile = aws_iam_instance_profile.ssm-iam-profile.name 
}

output "instance_id_k8s_worker_node02" {
  value = aws_instance.k8s-worker-node02.id
}

# Create an AWS linux instance on the public subnet
# This instance will play the role of an nginx server
# and it will be used to forward kubectl commands 
# to the master node of the cluster
# located in the private subnet

# create the interface
resource "aws_network_interface" "nginx_server_iface" {
  subnet_id   = aws_subnet.k8s_public_subnet.id
  security_groups = [aws_security_group.public.id]
  tags = {
    Name = "nginx_server_iface"
  }
}

output "private_ip_nginx_server" {
  value = aws_network_interface.nginx_server_iface.private_ip
}

# create the instance
resource "aws_instance" "nginx_server" {
  ami           = "ami-0cff7528ff583bf9a"
  key_name      = "main-key"
  network_interface {
    network_interface_id = aws_network_interface.nginx_server_iface.id
    device_index         = 0
  }
  instance_type = "t2.micro"
  user_data = "${data.cloudinit_config.nginx-server.rendered}"
  tags = {
    Name = "nginx-server"
  }
}

# get the public ip of the nginx server
output "public_ip_nginx_server" {
  value = aws_instance.nginx_server.public_ip
}

