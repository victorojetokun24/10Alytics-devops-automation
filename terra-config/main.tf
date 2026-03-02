provider "aws" {
  region = "us-east-1"
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "nginx-web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Install Docker, Git
    apt update -y
    apt install -y docker.io git

    systemctl enable docker
    systemctl start docker

    # Pull project and start Docker Compose
    cd /home/ubuntu
    git clone https://github.com/victorojetokun24/10Alytics-devops-automation.git
    cd 10Alytics-devops-automation

    # Wait briefly to ensure Docker is ready
    sleep 10
    docker compose up -d --build

    # Wait until nginx is responding on port 80
    until curl -s http://localhost:80 > /dev/null; do
      echo "Waiting for nginx..."
      sleep 5
    done
  EOF

  tags = {
    Name = "nginx-docker-instance"
  }
}

# Output public IP
output "public_ip" {
  value = aws_instance.web.public_ip
}