terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.28.0"
    }
  }

  required_version = ">1.2.0"
}

provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "vpc_main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main_VPC"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.vpc_main.id

  tags = {
    Name = "Main_IGW"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "main_rt"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.vpc_main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet_web"
  }
}

resource "aws_route_table_association" "rt_main_a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_security_group" "sg_web" {
  name        = "allow_web"
  description = "allows web traffic"
  vpc_id      = aws_vpc.vpc_main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "SSH"
    from_port   = 22
    protocol    = "-1"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "Main_SG"
  }
}

resource "aws_network_interface" "main_nic" {
  subnet_id = aws_subnet.main_subnet.id
  private_ips = ["10.0.1.50"]
  security_groups = [aws_security_group.sg_web.id]

}

resource "aws_eip" "main_elastic" {
  vpc = true
  network_interface = aws_network_interface.main_nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.main_igw]
}

resource "aws_instance" "ubuntu_server" {
  ami = "ami-052efd3df9dad4825"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"

  key_name = "main_key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.main_nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c "echo your very first web server > /var/www/html/index.html"
              EOF

  tags = {
    Name = "Web Server"
  }
}