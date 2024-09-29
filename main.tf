provider "aws" {
  region = "us-east-1"
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "main_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  map_public_ip_on_launch = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "main_cluster"
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets

  // https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    example = {
      ami_id = data.aws_ami.ubuntu.id
      //ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 2
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
/*
resource "aws_internet_gateway" "ig" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "main_vpc_internet_gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

  tags = {
    Name = "main_vpc_public_route_table"
  }
}
*/

data "aws_route_table" "public_route_table" {
  //count      = length(module.vpc.public_subnets)
  subnet_id  = module.vpc.public_subnets[0]
}

resource "aws_route_table_association" "public_rt_association" {
  //count      = length(module.vpc.public_subnets)
  subnet_id  = module.vpc.public_subnets[0]
  route_table_id = data.aws_route_table.public_route_table.id
}

data "aws_route_table" "public_route_table_1" {
  //count      = length(module.vpc.public_subnets)
  subnet_id  = module.vpc.public_subnets[1]
}

resource "aws_route_table_association" "public_rt_association_1" {
  //count      = length(module.vpc.public_subnets)
  subnet_id  = module.vpc.public_subnets[1]
  route_table_id = data.aws_route_table.public_route_table_1.id
}

resource "aws_lb" "nginx_lb" {
  name               = "nginx-lb"
  internal           = false
  load_balancer_type = "application"
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}