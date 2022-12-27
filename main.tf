resource "aws_vpc" "project_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "project-1VPC"
  }
}

resource "aws_subnet" "projectsubnet1" {
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "project-1subnet1"
  }
}

resource "aws_subnet" "projectsubnet2" {
  vpc_id     = aws_vpc.project_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "project-1subnet2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = "project-1gw"
  }
}

resource "aws_route_table" "project_rt" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }



  tags = {
    Name = "project-1rttable"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.projectsubnet1.id
  route_table_id = aws_route_table.project_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.projectsubnet2.id
  route_table_id = aws_route_table.project_rt.id
}

## security groups for terraform project
resource "aws_security_group" "terraform_sg" {
  name        = "terraform_sg"
  description = "SG for default page"
  vpc_id      = aws_vpc.project_vpc.id
  ingress {
    description = "ssh to my ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "http to my ip"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "terraform_sg"
  }
}


## load balancer security_group

resource "aws_security_group" "terraform_alb_sg" {
  name        = "terraform_alb_sg"
  description = "SG for ALB"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    description = "ssh from my ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "terraform_alb_sg"
  }
}