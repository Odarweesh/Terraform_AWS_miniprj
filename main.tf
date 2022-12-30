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

resource "aws_key_pair" "project_key" {
  key_name = "mini_project_key_tf"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLrQeHQhuP5F5o20buIU4BLibdOGd1LCIs/Me8Eb65ajWNVDW4QfgeKq+QiLMeevRTN2ycqUcXAiXS+TMMBjVjdw1oW4HqJmuXWte8xp/55TepiUikqRUrsKvjxGMBX3lro8Y9FgufJqZ5WbdHXgbSZZxQzu2Ywtq0/m8EcRf6fO7YCiEmUDWriRtE8Lug1U3fDqsSBwlJQIq0C/Ym+8g8Adv7ATltiJinFzKRtYObpDudVLe8OK9zn//FMZhYOlCox4DCQ9HCd91UV2SkK8TuErekYn6ifqddIWZalfB2r8XHCzke4uRI71LOUGMqlPZ65ajZ094KZ6btAytrunTx ec2-user@ip-172-31-84-37.ec2.internal"
}


resource "aws_instance" "Ec2_project" {
  ami           = "ami-0b5eea76982371e91"
  instance_type = "t2.micro"
  key_name = aws_key_pair.project_key.id
  subnet_id = aws_subnet.projectsubnet1.id
  vpc_security_group_ids = [aws_security_group.terraform_sg.id]
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
sudo -i
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
aws s3 cp s3://project-demo-bucket-tch/default/flowershop_default_page.html /var/www/html/index.html --no-sign-request
systemctl restart httpd
EOF

  tags = {
    Name = "default-page"
  }
 }

resource "aws_lb_target_group" "default-page-tg" {
  name = "default-page-tg-terraform"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.project_vpc.id
  #health_check = "/"
}

resource "aws_lb_target_group_attachment" "default-page-attachment" {
  target_group_arn = aws_lb_target_group.default-page-tg.arn
  target_id = aws_instance.Ec2_project.id
  port = 80
}

resource "aws_lb_listener" "load-balancer-default" {
  load_balancer_arn = aws_lb.miniproject.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default-page-tg.arn
  }
}

resource "aws_launch_configuration" "flowers-lc" {
  name = "flowers-launch-config"
  image_id = "ami-0b5eea76982371e91"
  instance_type = "t2.micro"
  key_name = aws_key_pair.project_key.id
  security_groups = [aws_security_group.terraform_sg.id]
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
sudo -i
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
mkdir /var/www/html/flowers/
aws s3 cp s3://project-demo-bucket-tch/flowers/flowershop_flower-page.html /var/www/html/flowers/index.html --no-sign-request
systemctl restart httpd
EOF

}

#flowers-page target group
resource "aws_lb_target_group" "flowers-page-tg" {
  name = "flowers-page-tg-terraform"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.project_vpc.id
  health_check {
    path = "/flowers/"
    port = 80
    healthy_threshold = 6
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
  }
}

#flowers-page autoscaling group
resource "aws_autoscaling_group" "flowers-page-asg" {
  name = "flowers-page-asg-terraform"
  max_size = 3
  min_size = 1
  desired_capacity = 1
  launch_configuration = aws_launch_configuration.flowers-lc.name
  vpc_zone_identifier = [aws_subnet.projectsubnet1.id, aws_subnet.projectsubnet2.id]
  #target_group_arns = aws_lb_target_group.flowers-page-tg.arn
}


# attach flowers-page autoscaling with target group
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.flowers-page-asg.id
  lb_target_group_arn    = aws_lb_target_group.flowers-page-tg.arn
}

# load balancer listener rule to forward flowers page traffic to flowers page
resource "aws_lb_listener_rule" "flowers-page-rule" {
  listener_arn = aws_lb_listener.load-balancer-default.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flowers-page-tg.arn
  }

  condition {
    path_pattern {
      values = ["*/flowers*"]
    }
  }
}
