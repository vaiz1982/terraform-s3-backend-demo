# Terraform конфигурация
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider конфигурация
provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

# ============================================
# 1. СОЗДАНИЕ S3 БАКЕТА ДЛЯ TFSTATE
# ============================================

# S3 бакет для хранения tfstate

# Включение версионирования для возможности отката

# Включение шифрования

# Блокировка публичного доступа

# ============================================
# 2. СОЗДАНИЕ DYNAMODB ДЛЯ БЛОКИРОВКИ TFSTATE
# ============================================

# DynamoDB таблица для блокировки state файла

# ============================================
# 3. СОЗДАНИЕ EC2 ИНСТАНСА
# ============================================

# Security Group для EC2 инстанса
resource "aws_security_group" "demo_instance" {
  name        = "${var.environment}-demo-instance-sg"
  description = "Security group for demo EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  # SSH доступ (только с вашего IP для безопасности)
  ingress {
    description = "SSH from allowed IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # HTTP доступ (для демо)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS доступ (для демо)
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Исходящий трафик - всё разрешено
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-demo-sg"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Получение последнего Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 инстанс
resource "aws_instance" "demo" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.demo_instance.id]
  key_name               = var.key_name

  # User data скрипт для установки веб-сервера (опционально)
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Demo Instance from Terraform</h1>" > /var/www/html/index.html
    echo "<p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
    echo "<p>Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>" >> /var/www/html/index.html
  EOF

  # Тэг Type: Demo как требуется
  tags = {
    Name        = "${var.environment}-demo-instance"
    Type        = "Demo"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Created     = timestamp()
  }

  # Включаем мониторинг
  monitoring = true

  # Root volume настройки
  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true

    tags = {
      Name        = "${var.environment}-demo-root-volume"
      Environment = var.environment
    }
  }
}

# Эластичный IP (опционально)
resource "aws_eip" "demo" {
  instance = aws_instance.demo.id
  domain   = "vpc"

  tags = {
    Name        = "${var.environment}-demo-eip"
    Environment = var.environment
    Type        = "Demo"
  }
}

# ============================================
# DATA SOURCES
# ============================================

# Получение default VPC
data "aws_vpc" "default" {
  default = true
}

# Получение информации о текущем пользователе (для отладки)
data "aws_caller_identity" "current" {}

# Получение текущего региона
data "aws_region" "current" {}
