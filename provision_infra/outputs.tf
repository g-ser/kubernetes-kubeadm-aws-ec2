output "private_ip_nat_gw" {
  description = "get the private ip of the nat gateway"
  value       = aws_nat_gateway.this.private_ip
}

output "instance_id_master_node" {
  description = "EC2 instance ID of master node"
  value       = aws_instance.ec2_nodes["k8s_master_node"].id
}

output "instance_id_k8s_worker_node01" {
  description = "Instance ID of EC2 worker node01"
  value       = aws_instance.ec2_nodes["k8s_worker_node01"].id
}

output "instance_id_k8s_worker_node02" {
  description = "Instance ID of EC2 worker node02"
  value       = aws_instance.ec2_nodes["k8s_worker_node02"].id
}

output "public_ip_nginx_server" {
  description = "The public IP of the nginx server"
  value       = aws_instance.ec2_nodes["nginx_server"].public_ip
}

output "private_ip_nginx_server" {
  description = "Private IP address of the nginx server"
  value       = aws_network_interface.nginx_server_iface.private_ip
}

output "instance_id_nginx_server" {
  description = "Instance ID of the nginx server"
  value       = aws_instance.ec2_nodes["nginx_server"].id
}