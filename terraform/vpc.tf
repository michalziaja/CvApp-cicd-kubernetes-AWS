resource "aws_vpc" "eks_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}/VPC"
  }
}

resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = element(["192.168.64.0/19", "192.168.32.0/19"], count.index)
  availability_zone       = element(["eu-central-1a", "eu-central-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name                      = "${var.cluster_name}/SubnetPublic${count.index}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = element(["192.168.160.0/19", "192.168.128.0/19"], count.index)
  availability_zone = element(["eu-central-1a", "eu-central-1b"], count.index)

  tags = {
    Name                                 = "${var.cluster_name}/SubnetPrivate${count.index}"
    "kubernetes.io/role/internal-elb"    = "1"
  }
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}/InternetGateway"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.cluster_name}/NATIP"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public.*.id, 2)

  tags = {
    Name = "${var.cluster_name}/NATGateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}/PublicRouteTable"
  }
}

resource "aws_route_table" "private" {
  count = 3
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}/PrivateRouteTable${count.index}"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks_igw.id
}

resource "aws_route" "private_route" {
  count                  = 3
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route_table_association" "public_association" {
  count = 3
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_association" {
  count = 3
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_security_group" "eks_cluster_security_group" {
  vpc_id = aws_vpc.eks_vpc.id
  name   = "${var.cluster_name}-eks-cluster-sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "${var.cluster_name}/ClusterSharedNodeSecurityGroup"
  }
}

resource "aws_security_group" "eks_control_plane_security_group" {
  vpc_id = aws_vpc.eks_vpc.id
  name   = "${var.cluster_name}-eks-control-plane-sg"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "${var.cluster_name}/ControlPlaneSecurityGroup"
  }
}
resource "aws_security_group" "ec2_admin_security_group" {
  vpc_id = aws_vpc.eks_vpc.id
  name   = "${var.cluster_name}-ec2-admin-sg"

  ingress = [
    for port in [22, 80] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      ipv6_cidr_blocks = ["::/0"]
      self             = false
      prefix_list_ids  = []
      security_groups  = []
      cidr_blocks      = ["0.0.0.0/0"]
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.cluster_name}/EC2AdminSecurityGroup"
  }
}
