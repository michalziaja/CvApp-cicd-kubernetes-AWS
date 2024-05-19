module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = var.eks_vpc_name
  cidr = "10.20.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}












# resource "aws_vpc" "eks_vpc" {
#   cidr_block = "192.168.0.0/16"
#   enable_dns_support = true
#   enable_dns_hostnames = true
#   tags = {
#     Name = "eks_vpc"
#   }
# }

# resource "aws_subnet" "public_subnet_a" {
#   vpc_id            = aws_vpc.eks_vpc.id
#   cidr_block        = "192.168.32.0/19"
#   availability_zone = "eu-central-1a"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "public_subnet_a"
#   }
# }

# resource "aws_subnet" "public_subnet_b" {
#   vpc_id            = aws_vpc.eks_vpc.id
#   cidr_block        = "192.168.64.0/19"
#   availability_zone = "eu-central-1b"
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "public_subnet_b"
#   }
# }

# resource "aws_subnet" "private_subnet_a" {
#   vpc_id            = aws_vpc.eks_vpc.id
#   cidr_block        = "192.168.96.0/19"
#   availability_zone = "eu-central-1a"
#   tags = {
#     Name = "private_subnet_a"
#   }
# }

# resource "aws_subnet" "private_subnet_b" {
#   vpc_id            = aws_vpc.eks_vpc.id
#   cidr_block        = "192.168.128.0/19"
#   availability_zone = "eu-central-1b"
#   tags = {
#     Name = "private_subnet_b"
#   }
# }

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.eks_vpc.id
#   tags = {
#     Name = "igw"
#   }
# }

# resource "aws_route_table" "public_rt" {
#   vpc_id = aws_vpc.eks_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
#   tags = {
#     Name = "public_rt"
#   }
# }

# resource "aws_route_table_association" "public_rt_assoc_a" {
#   subnet_id      = aws_subnet.public_subnet_a.id
#   route_table_id = aws_route_table.public_rt.id
# }

# resource "aws_route_table_association" "public_rt_assoc_b" {
#   subnet_id      = aws_subnet.public_subnet_b.id
#   route_table_id = aws_route_table.public_rt.id
# }

# resource "aws_security_group" "eks_cluster_sg" {
#   vpc_id = aws_vpc.eks_vpc.id
#   description = "EKS cluster security group"
#   tags = {
#     Name = "eks_cluster_sg"
#   }
# }
