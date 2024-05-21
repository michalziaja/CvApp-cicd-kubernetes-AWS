

resource "aws_instance" "ec2" {
  ami                    = "ami-026c3177c9bd54288"
  instance_type          = var.ec2_instance_type
  iam_instance_profile   = aws_iam_instance_profile.ec2_admin_profile.name
  vpc_security_group_ids = [aws_security_group.ec2_admin_security_group.id]
  subnet_id              = element(aws_subnet.public.*.id, 0)
  key_name               = var.key_name

  tags = {
    Name = "${var.cluster_name}/EksHostInstance"
  }

  user_data = <<EOF
#!/bin/bash
echo "Install aws-cli"
sudo snap install aws-cli --classic
EOF
}

resource "null_resource" "sleep" {
  depends_on = [ aws_instance.ec2 ]
  provisioner "local-exec" {
    command = "sleep 15"  
  }
}

resource "null_resource" "copy_install_script" {
  depends_on = [ null_resource.sleep ]

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



