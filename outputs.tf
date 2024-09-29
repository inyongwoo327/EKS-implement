output "eks_cluster_name" {
    value = "module.eks.cluster_name"
}

output "cluster_region" {
    value = var.aws_region
}

output "kubeconfig_file_path" {
    value = "${path.module}/kubeconfig"
}

output "nginx_service_url" {
    value = aws_lb.nginx_lb.dns_name
}

output "workspace" {
    value = "workspace ${terraform.workspace}"
}