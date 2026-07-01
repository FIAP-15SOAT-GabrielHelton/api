output "rds_endpoint" {
  description = "The endpoint of the RDS PostgreSQL instance"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "The address of the RDS PostgreSQL instance"
  value       = aws_db_instance.postgres.address
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_endpoint" {
  description = "The endpoint of the EKS cluster control plane"
  value       = aws_eks_cluster.main.endpoint
}
