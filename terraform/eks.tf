


# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = ">=20.0"
  
#   cluster_name    = var.cluster_name
#   cluster_version = "1.29"

#   vpc_id = module.vpc.vpc_id 
#   subnet_ids = module.vpc.private_subnets
#   cluster_endpoint_public_access  = true
#   iam_role_name = aws_iam_role.eks_role.name
# }
#   eks_managed_node_group_defaults = {
#     ami_type = "AL2_x86_64"
#   }

#   eks_managed_node_groups = {
#     one = {
#       name = "master-node-group"  
#       instance_types = ["t2.micro"]
#       min_size     = 1
#       max_size     = 1
#       desired_size = 1
#     },
#     two = {
#       name = "worker-node-group"  
#       instance_types = ["t2.micro"]
#       min_size     = 1
#       max_size     = 1
#       desired_size = 1
#     }
#   }
# }


# resource "aws_eks_node_group" "eks_node_group" {
#   cluster_name    = var.cluster_name
#   node_group_name = "eks_node_group"
#   node_role_arn   = aws_iam_role.eks_node_role.arn
#   subnet_ids = module.vpc.private_subnets

#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   instance_types = ["t2.micro"]
# }



module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">=20.0"
  
  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id = module.vpc.vpc_id 
  subnet_ids = module.vpc.private_subnets
  cluster_endpoint_public_access  = true
  iam_role_name = aws_iam_role.eks_role.name

  
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "eks_node_group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t2.micro"]

  depends_on = [
    module.eks
  ]
}






