resource "aws_instance" "ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.security-group.id]
  iam_instance_profile   = aws_iam_instance_profile.instance-profile.name

  # root_block_device {
  #   volume_size = 20
  # }
  provisioner "remote-exec" {
  inline = ["echo 'Wait until SSH is ready'"]
  
  connection {
      type        = "ssh"
      host        = aws_instance.ec2.public_ip
      user        = "ubuntu"
      private_key = file(var.private_key_path)
    }
  }
  tags = {
    Name = var.instance_name
  }
} 

resource "null_resource" "copy_install_script" {
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

  depends_on = [aws_instance.ec2]
}