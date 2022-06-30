# k8s-master-node

data "cloudinit_config" "master_node" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.ssm-agent.content
  }

  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.apache.content
  }

}

# k8s-worker-node01

data "cloudinit_config" "k8s-worker-node01" {
  gzip          = true
  base64_encode = true

  
  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.ssm-agent.content
  }

}

# k8s-worker-node02

data "cloudinit_config" "k8s-worker-node02" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.ssm-agent.content
  }

}

# nginx-server

data "cloudinit_config" "nginx-server" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      =  data.local_file.nginx-install.content
  }

}

# script that installs nginx server

data "local_file" "nginx-install" {
  filename = "${path.module}/scripts/install-nginx.sh"
}

# script that installs ssm agent

data "local_file" "ssm-agent" {
  filename = "${path.module}/scripts/ssm-agent-install.sh"
}

# script that installs apache web server

data "local_file" "apache" {
  filename = "${path.module}/scripts/install-apache.sh"
}
