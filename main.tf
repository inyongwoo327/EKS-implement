/*
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
*/

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