module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "main_vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway      = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${module.vpc.name}-igw"
  }
}

# Create a public route table
resource "aws_route_table" "public_rt" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${module.vpc.name}-public-rt"
  }
}

# Associate the first public subnet with the public route table
resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = module.vpc.public_subnets[0]
  route_table_id = aws_route_table.public_rt.id
}

# Associate the second public subnet with the public route table
resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = module.vpc.public_subnets[1]
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_lb" "nginx_lb" {
  name               = "nginx-lb"
  internal           = false
  load_balancer_type = "application"
  subnets = module.vpc.public_subnets
  enable_deletion_protection = false
}
