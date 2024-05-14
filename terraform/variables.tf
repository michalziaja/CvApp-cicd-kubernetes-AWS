variable "region" {
  description = "Region"
  type = string
  default = "eu-central-1"
}

variable "vpc-name" {
  description = "VPC for host"
  type = string
  default = "host-vpc"
}

variable "igw-name" {
  description = "IG"
  type = string
  default = "host-igw"
}

variable "subnet-name" {
  description = "Subnet"
  type = string
  default = "host-subnet"
}

variable "rt-name" {
  description = "Route Table"
  type = string
  default = "host-rt"
}

variable "sg-name" {
  description = "Security Group"
  type = string
  default = "host-sg"
}


variable "iam-role" {
  description = "IAM Role"
  type = string
  default = "host-iam-role"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-026c3177c9bd54288" // Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2024-04-11
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.large"
}

variable "key_name" {
  description = "EC2 keypair"
  type        = string
  default     = "project"
}

variable "instance_name" {
  description = "EC2 name"
  type        = string
  default     = "host-server"
}
#