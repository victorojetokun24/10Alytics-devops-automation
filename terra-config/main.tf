# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a security group for the EC2 instance
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

# Get the default VPC and the latest Ubuntu AMI
data "aws_vpc" "default" {
  default = true
}

# Get the latest Ubuntu AMI for the specified region
data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["amazon"]
  
      filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
      }

      filter {
        name   = "virtualization-type"
        values = ["hvm"]
      }
    }

# Create an EC2 instance and install Docker, Docker Compose, and Git using user data
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io docker-compose git
              systemctl start docker
              systemctl enable docker
              cd /home/ubuntu
              git clone https://github.com/victorojetokun24/10Alytics-devops-automation.git 
              cd 10Alytics-devops-automation/
              docker-compose up -d --build
              EOF

# Add tags to the instance
  tags = {
    Name = "nginx-docker-instance"
  }
}

# Output the public IP address of the EC2 instance
output "public_ip" {
  value       = aws_instance.web.public_ip
}
