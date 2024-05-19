
resource "aws_instance" "ec2" {
  ami                    = "ami-026c3177c9bd54288"
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2_admin_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_admin_security_group.id]
  subnet_id              = element(aws_subnet.public.*.id, 0)
  key_name               = var.key_name

  tags = {
    Name = "${var.cluster_name}/EKSAdminInstance"
  }

  user_data = <<EOF
    # Update and install dependencies
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates curl unzip jq

    # Install aws-cli
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    EOF
}

resource "null_resource" "sleep" {
  depends_on = [ aws_instance.ec2 ]
  provisioner "local-exec" {
    command = "sleep 15"  
  }
}

resource "null_resource" "copy_install_script" {
  depends_on = [null_resource.sleep]

  provisioner "file" {
    source      = "${path.module}/install.sh"
    destination = "/home/ubuntu/install.sh"
    connection {
      type        = "ssh"
      host        = aws_instance.ec2.public_ip
      user        = "ubuntu"
      private_key = file(var.private_key_path)
    }
  }

  provisioner "file" {
    source      = "${path.module}/install2.sh"
    destination = "/home/ubuntu/install2.sh"
    connection {
      type        = "ssh"
      host        = aws_instance.ec2.public_ip
      user        = "ubuntu"
      private_key = file(var.private_key_path)
    }
  }
}



# #sudo apt  install awscli

# # Install kubectl
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl
# sudo mv kubectl /usr/local/bin/

# echo "Install Eksctl"
# curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
# sudo mv /tmp/eksctl /usr/local/bin
# #eksctl version

# # Configure kubectl
# #aws eks update-kubeconfig --region eu-central-1 --name cvapp-eks
# 
 