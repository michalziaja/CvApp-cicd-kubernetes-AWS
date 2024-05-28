data "aws_vpc" "default" {
  default = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "cvapp-eks"
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "Node-group-cvapp"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "private_key_path" {
  description = "Private Key"
  type        = string
  default     = "./private_key.pem"
}
variable "region" {
  description = "Region"
  type = string
  default = "eu-central-1"
}
variable "key_name" {
  description = "EC2 keypair"
  type        = string
  default     = "project"
}