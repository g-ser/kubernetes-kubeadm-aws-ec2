variable "region" {
  description = "The AWS region where the infrastructure will be provisioned"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The cidr block of the VPC"
  type        = string
}

variable "private_subnet_cidr_block" {
  description = "The cidr block of the private subnet"
  type        = string
}

variable "public_subnet_cidr_block" {
  description = "The cidr block of the public subnet"
  type        = string
}

variable "credentials_location" {
  description = "The location in your local machine of the aws_access_key_id and aws_secret_access_key"
  type        = string
}

variable "master_node_ip_address" {
  description = "The IP address of the master node. The one where the control plane components reside"
  type        = string
}

variable "worker_node01_ip_address" {
  description = "The IP address of the 1st worker node of the k8s cluster."
  type        = string
}

variable "worker_node02_ip_address" {
  description = "The IP address of the 2nd worker node of the k8s cluster."
  type        = string
}

variable "master_node_ami" {
  description = "The AWS ami from which the EC2 instance representing the master node will be created"
  type        = string
}

variable "master_node_instance_type" {
  description = "The instance type of the master node"
  type        = string
}

variable "worker_node_ami" {
  description = "The AWS ami from which the EC2 instance representing the worker nodes will be created"
  type        = string
}

variable "worker_node_instance_type" {
  description = "The instance type of the worker nodes"
  type        = string
}

variable "nginx_server_ami" {
  description = "The AWS ami used for the the nginx server"
  type        = string
}

variable "nginx_server_instance_type" {
  description = "The instance type of the nginx server"
  type        = string
}

variable "key_name" {
  description = "Key name of the key pair used to connect to EC2 instances"
  type        = string
}