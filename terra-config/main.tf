# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a security group for the web server
resource "aws_security_group" "web_sg" {
  name        = "nginx-web-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

# Allow inbound traffic on port 80 (HTTP) and port 22 (SSH)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Allow inbound traffic on port 22 (SSH) for remote access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]
  
      filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
      }

      filter {
        name   = "virtualization-type"
        values = ["hvm"]
      }
    }

# Create an EC2 instance for the web server
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  # associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.web_sg.id]

# Use user data to install Docker, Docker Compose, Git, and set up the application
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update system
              apt-get update -y

              # Install prerequisites
              apt-get install -y ca-certificates curl gnupg git

              # Add Docker official GPG key
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg

              # Add Docker repo
              echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
                > /etc/apt/sources.list.d/docker.list

              # Install Docker Engine + Compose plugin
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

              # Start and enable Docker
              systemctl enable docker
              systemctl start docker

              # Clone project
              cd /home/ubuntu
              git clone https://github.com/victorojetokun24/10Alytics-devops-automation.git
              cd 10Alytics-devops-automation

              # Run containers
              docker compose up -d --build
              EOF

  tags = {
    Name = "nginx-docker-instance"
  }
}

# Output the public IP address of the EC2 instance
output "public_ip" {
  value       = aws_instance.web.public_ip
}

