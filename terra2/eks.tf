
resource "aws_eks_cluster" "eks_cluster" {
  depends_on = [ null_resource.sleep ]
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = concat(aws_subnet.public.*.id, aws_subnet.private.*.id)
    endpoint_public_access = true
    security_group_ids = [aws_security_group.eks_control_plane_security_group.id]
  }

  tags = {
    Name = "${var.cluster_name}/ControlPlane"
  }
}


resource "aws_eks_node_group" "eks_node_group" {
  depends_on = [ aws_eks_cluster.eks_cluster ]
  
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "ng-${var.node_group_name}"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private.*.id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }
  instance_types = ["t2.small"]

  tags = {
    Name = "${var.cluster_name}/NodeGroup"
  }
}