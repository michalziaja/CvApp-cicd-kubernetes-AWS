resource "aws_iam_role" "eks_cluster_role" {
  name = "eks_cluster_role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role_policy.json
  tags = {
    Name = "${var.cluster_name}/ServiceRole"
  }
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks_node_role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json

  tags = {
    Name = "${var.cluster_name}/NodeInstanceRole"
  }
}


data "aws_iam_policy_document" "eks_cluster_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy_attachment" {
  for_each = {
    "AmazonEKSClusterPolicy"               = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    "AmazonEKSVPCResourceController"       = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  }

  policy_arn = each.value
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy_attachment" {
  for_each = {
    "AmazonEKSWorkerNodePolicy"            = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    "AmazonEC2ContainerRegistryReadOnly"   = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    "AmazonEKS_CNI_Policy"                 = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  }
  policy_arn = each.value
  role       = aws_iam_role.eks_node_role.name
}



#############EC2 INSTANCE#####################



resource "aws_iam_role" "ec2_admin_role" {
  name = "ec2_admin_role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json

  tags = {
    Name = "${var.cluster_name}/EC2AdminRole"
  }
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ec2_admin_policy_attachment" {
  role       = aws_iam_role.ec2_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2_admin_profile" {
  name = "ec2_admin_profile"
  role = aws_iam_role.ec2_admin_role.name
}