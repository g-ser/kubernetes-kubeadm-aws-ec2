# k8s-master-node

data "cloudinit_config" "master_node" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.ssm_agent.content
  }

  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.apache.content
  }

}

# k8s-worker-node01

data "cloudinit_config" "k8s_worker_node01" {
  gzip          = true
  base64_encode = true

  
  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.ssm_agent.content
  }

}

# k8s-worker-node02

data "cloudinit_config" "k8s_worker_node02" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.ssm_agent.content
  }

}

# nginx-server

data "cloudinit_config" "nginx_server" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.nginx_install.content
  }

}

# script that installs nginx server

data "local_file" "nginx_install" {
  filename = "${path.module}/scripts/install-nginx.sh"
}

# script that installs ssm agent

data "local_file" "ssm_agent" {
  filename = "${path.module}/scripts/ssm-agent-install.sh"
}

# script that installs apache web server

data "local_file" "apache" {
  filename = "${path.module}/scripts/install-apache.sh"
}
