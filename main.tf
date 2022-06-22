terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

variable "availabilty_zone" {
  default = "ap-east-1a"
}

variable "nginx_names" {
  description = "VM Names"
  default     = ["nginx1", "nginx2"]
  type        = set(string)
}

variable "appsrv_names" {
  description = "VM Names"
  default     = ["app1", "app2"]
  type        = set(string)
}


provider "aws" {
  region = "ap-east-1"
}

resource "aws_vpc" "bientfvpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name  = "bientf-vpc"
    Owner = "bien.nguyen@f5.com"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.bientfvpc.id
  tags = {
    Name  = "bientf-igw"
    Owner = "bien.nguyen@f5.com"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.bientfvpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route_table_association" "route_table_external" {
  subnet_id      = aws_subnet.external.id
  route_table_id = aws_vpc.bientfvpc.main_route_table_id
}

resource "aws_route_table_association" "route_table_internal" {
  subnet_id      = aws_subnet.internal.id
  route_table_id = aws_vpc.bientfvpc.main_route_table_id
}

resource "aws_subnet" "management" {
  vpc_id                  = aws_vpc.bientfvpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availabilty_zone
  tags = {
    Name  = "bien-tf-management-subnet"
    Owner = "bien.nguyen@f5.com"
  }
}

resource "aws_subnet" "external" {
  vpc_id                  = aws_vpc.bientfvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availabilty_zone
  tags = {
    Name  = "bien-tf-external-subnet"
    Owner = "bien.nguyen@f5.com"
  }
}

resource "aws_subnet" "internal" {
  vpc_id                  = aws_vpc.bientfvpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.availabilty_zone
  tags = {
    Name  = "bien-tf-internal-subnet"
    Owner = "bien.nguyen@f5.com"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "an allow all security group used in terraform"
  vpc_id      = aws_vpc.bientfvpc.id
  tags = {
    Name  = "bien-tf-securitygroup_allow_all"
    Owner = "bien.nguyen@f5.com"
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "appsrv" {
  for_each                    = toset(var.appsrv_names)
  ami                         = "ami-0350928fdb53ae439"
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  availability_zone           = aws_subnet.external.availability_zone
  subnet_id                   = aws_subnet.external.id
  security_groups             = ["${aws_security_group.allow_all.id}"]
  vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
  key_name                    = "biennguyen-hk"
  user_data                   = file("userdata_ubuntu_appsrv.sh")
  root_block_device { delete_on_termination = true }
  tags = {
    Name  = each.value
    Owner = "bien.nguyen@f5.com"
  }
}

resource "aws_instance" "nginx" {
  for_each                    = toset(var.nginx_names)
  ami                         = "ami-0350928fdb53ae439"
  instance_type               = "t3.small"
  associate_public_ip_address = true
  availability_zone           = aws_subnet.external.availability_zone
  subnet_id                   = aws_subnet.external.id
  security_groups             = ["${aws_security_group.allow_all.id}"]
  vpc_security_group_ids      = ["${aws_security_group.allow_all.id}"]
  key_name                    = "biennguyen-hk"
  user_data                   = file("userdata_ubuntu_nginx.sh")
  root_block_device { delete_on_termination = true }
  tags = {
    Name  = each.value
    Owner = "bien.nguyen@f5.com"
  }
}


output "appsrv_public_ip" {
  value = {
    for k, v in aws_instance.appsrv : k => v.public_ip
  }
}

output "nginx_public_ip" {
  value = {
    for k, v in aws_instance.nginx : k => v.public_ip
  }
}

