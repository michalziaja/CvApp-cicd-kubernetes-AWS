resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  iam_instance_profile   = aws_iam_instance_profile.host-profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 8
  }
  tags = {
    Name = var.instance_name
  }
} 

resource "null_resource" "sleep" {
  depends_on = [ aws_instance.ec2 ]
  provisioner "local-exec" {
    command = "sleep 30"  
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
