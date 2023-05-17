provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "example_vpc"
  }
}

resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id
  tags = {
    Name = "example_igw"
  }
}

resource "aws_subnet" "example_public_subnet_1" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "example_public_subnet_1"
  }
}

resource "aws_subnet" "example_public_subnet_2" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
  tags = {
    Name = "example_public_subnet_2"
  }
}

resource "aws_route_table" "example_public_rt" {
  vpc_id = aws_vpc.example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example_igw.id
  }

  tags = {
    Name = "example_public_rt"
  }
}

resource "aws_route_table_association" "example_public_rta_1" {
  subnet_id      = aws_subnet.example_public_subnet_1.id
  route_table_id = aws_route_table.example_public_rt.id
}

resource "aws_route_table_association" "example_public_rta_2" {
  subnet_id      = aws_subnet.example_public_subnet_2.id
  route_table_id = aws_route_table.example_public_rt.id
}

resource "aws_security_group" "example_sg" {
  name        = "example_sg"
  description = "Allow inbound SSH and HTTP traffic"
  vpc_id      = aws_vpc.example_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example_ec2_instance_1" {
  ami                         = "i-0a18d3b3a4663f32c"
  instance_type               = "t2.micro"
  key_name                    = "key-038e40e450e5fe054"
  vpc_security_group_ids      = [aws_security_group.example_sg.id]
  subnet_id                   = aws_subnet.example_public_subnet_1.id
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Встановлення Docker та Docker Compose
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo apt-get install -y docker-compose

              # Завантаження та запуск Prometheus stack
              sudo docker run -d --name prometheus -p 9090:9090 prom/prometheus

              # Завантаження та запуск Node Exporter
              sudo docker run -d --name node-exporter -p 9100:9100 prom/node-exporter

              # Завантаження та запуск Cadvizor Exporter
              sudo docker run -d --name cadvisor-exporter -p 8080:8080 google/cadvisor
              EOF

  provisioner "remote-exec" {
    inline = [
      "sudo docker run -d --name prometheus -p 9090:9090 prom/prometheus",
      "sudo docker run -d --name node-exporter -p 9100:9100 prom/node-exporter",
      "sudo docker run -d --name cadvisor-exporter -p 8080:8080 google/cadvisor"
    ]
  }
}

resource "aws_instance" "example_ec2_instance_2" {
  ami                         = "i-0a18d3b3a4663f32c"
  instance_type               = "t2.micro"
  key_name                    = "key-038e40e450e5fe054"
  vpc_security_group_ids      = [aws_security_group.example_sg.id]
  subnet_id                   = aws_subnet.example_public_subnet_2.id
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              # Встановлення Docker та Docker Compose
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo apt-get install -y docker-compose

              # Завантаження та запуск Node Exporter
              sudo docker run -d --name node-exporter -p 9100:9100 prom/node-exporter

              # Завантаження та запуск Cadvizor Exporter
              sudo docker run -d --name cadvisor-exporter -p 8080:8080 google/cadvisor
              EOF

  provisioner "remote-exec" {
    inline = [
      "sudo docker run -d --name node-exporter -p 9100:9100 prom/node-exporter",
      "sudo docker run -d --name cadvisor-exporter -p 8080:8080 google/cadvisor"
    ]
  }
}
