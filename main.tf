# Call the VPC module first
module "vpc" {
  source = "./vpc" # Path to the vpc module directory
}

# Call the EKS module and reference the VPC outputs
module "eks" {
  source = "./eks" # Path to the eks module directory
  
  depends_on = [
    module.vpc
  ]
}