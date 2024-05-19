
output "host_public_ip" {
  description = "host public IP"
  value       = aws_instance.ec2.public_ip
}
# output "eks_cluster_endpoint" {
#   value = aws_eks_cluster.eks_cluster.endpoint
# }

# output "eks_cluster_name" {
#   value = aws_eks_cluster.eks_cluster.name
# }

# output "eks_node_group_name" {
#   value = aws_eks_node_group.eks_node_group.node_group_name
# }

