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

resource "aws_s3_bucket" "aws_sBucket" {
  bucket = var.my_bucket_name

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.aws_sBucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.aws_sBucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.aws_sBucket.arn,
          "${aws_s3_bucket.aws_sBucket.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_object" "object" {
  bucket = var.my_bucket_name
  key    = "index.html"
  source = "./www/index.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./www/index.html")
}

resource "aws_lb" "miniproject" {
  name               = "miniproject-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terraform_alb_sg.id]
  subnets            = [aws_subnet.projectsubnet1.id, aws_subnet.projectsubnet2.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}

# resource "aws_instance" "Ec2_project" {
# ami           = "ami-0b5eea76982371e91"
# instance_type = "t2.micro"
# tags = {
# Name = "Ec2-project"
# }
# }

