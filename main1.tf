############# provider ##########
provider "aws" {
    region = "us-west-1"
} 

 terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.36.1"
    }
  }
}

########## Security group ###########3
resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
  }
  ingress {
    description      = "jenkins_port"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "demo-sg"
  }
}


############# vpc ############

resource "aws_vpc" "first-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "production"
  }

}

############## instance ##################
resource "aws_instance" "jenkins1" {
  ami                       = "ami-017c001a88dd93847"
  instance_type             = "t2.medium"
  key_name                  = "ravi"
  
  


  user_data = <<-EOF
  #!/bin/bash
  sudo yum update –y
  sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
  sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
  sudo yum upgrade -y 
  sudo amazon-linux-extras install java-openjdk11 -y
  sudo yum install jenkins -y
  sudo systemctl enable jenkins
  sudo systemctl start jenkins
  EOF  


}