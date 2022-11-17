provider "aws" {
    region = "us-east-1"
} 

 terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.36.1"
    }
  }
}



resource "aws_instance" "webserver1" {
  count = 2
  
  subnet_id = aws_subnet.main.id
  ami = "ami-09d3b3274b6c5d4aa" 
  instance_type = "t2.micro"
  user_data = "${file("userdata.sh")}"
  tags = {
    Name = "webserver1-${count.index}"
  }
  associate_public_ip_address = "true"
  key_name = "main"
}


resource "aws_lb" "test" {
  name               = "lb1"
  internal           = false
  load_balancer_type = "application"
  #security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.main.id, aws_subnet.public.id]

  enable_deletion_protection = false
 
}
resource "aws_vpc" "vpc1" {
  enable_dns_hostnames = true
  cidr_block = "10.0.0.0/16"
	tags = { 
  		Name = "vpc1"
	}
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet1"
  }
}
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "subnet2"
  }
}
resource "aws_security_group" "sg1" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "ig"
  }
}
resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  }
resource "aws_route_table_association" "rt2" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.test.arn
  port              = "8080"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
 # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }
}

resource "aws_lb_target_group" "test" {
  name     = "alb-target"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc1.id
}
resource "aws_lb_target_group_attachment" "test" {
  count = 2
  target_group_arn = aws_lb_target_group.test.arn
  target_id        = aws_instance.webserver1[count.index].id 
  port             = 8080
}