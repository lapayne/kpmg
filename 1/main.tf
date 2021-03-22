#############################################################################
# TODO                                                                      #
#   Find out what ports are required and add in security groups to allow it #
#   Add in autoscaling groups in the pub and priv tiers if using VM's       #
#############################################################################

terraform {
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.33.0"
    }
  }
}
#set up access to the account and set the region we want to work in
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  
}

#build a VPC to hold the subnets
resource "aws_vpc" "kpmg_3tier" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Client = var.client_name
  }
}

#public facing tier
resource "aws_subnet" "kpmgpub" {
  vpc_id                  = aws_vpc.kpmg_3tier.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Client = var.client_name
  }
}

#private tier
resource "aws_subnet" "kpmgprv" {
  vpc_id                  = aws_vpc.kpmg_3tier.id
  cidr_block              = "172.16.4.0/24"
  map_public_ip_on_launch = false

  tags = {
    Client = var.client_name
  }
}

#internal tier
resource "aws_subnet" "kpmgint" {
  vpc_id                  = aws_vpc.kpmg_3tier.id
  cidr_block              = "172.16.7.0/24"
  map_public_ip_on_launch = false

  tags = {
    Client = var.client_name
  }
}

#set up an internet gateway to allow public access/outbound
resource "aws_internet_gateway" "kpmgigw" {
  vpc_id = aws_vpc.kpmg_3tier.id

  tags = {
    Client = var.client_name
  }
}

#set a default route so everything in and out goes via the internet gateway
resource "aws_route_table" "kpmgrt" {
  vpc_id = aws_vpc.kpmg_3tier.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kpmgigw.id
  }

  tags = {
    Client = var.client_name
  }
}

#asociate the route table with the subnet
resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.kpmgpub.id
  route_table_id = aws_route_table.kpmgrt.id
}

#create an elastic IP
resource "aws_eip" "kpmgeip" {
  vpc = true

  tags = {
    Client = var.client_name
  }
}

#add the NAT gateway to the public tier to prevent inbound access directly
resource "aws_nat_gateway" "kpmgngw" {
  allocation_id = aws_eip.kpmgeip.id
  subnet_id     = aws_subnet.kpmgpub.id

  tags = {
    Client = var.client_name
  }
}

#add in additional route tables
resource "aws_route_table" "kpmgprvrt" {
  vpc_id = aws_vpc.kpmg_3tier.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kpmgngw.id
  }

  tags = {
    Client = var.client_name
  }
}
resource "aws_route_table" "kpmgintrt" {
  vpc_id = aws_vpc.kpmg_3tier.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kpmgngw.id
  }

  tags = {
    Client = var.client_name
  }
}

#assoiate route tables with the other networks
resource "aws_route_table_association" "kpmgprirtassoc" {
  subnet_id      = aws_subnet.kpmgprv.id
  route_table_id = aws_route_table.kpmgprvrt.id
}

#assoiate route tables with the other networks
resource "aws_route_table_association" "kpmgintrtassoc" {
  subnet_id      = aws_subnet.kpmgint.id
  route_table_id = aws_route_table.kpmgintrt.id
}

#create a load balancer and bind it to the public and private subnets allowing http/https
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "kpmgalb"

  load_balancer_type = "application"

  vpc_id             = aws_vpc.kpmg_3tier.id
  subnets            = [aws_subnet.kpmgpub.id, aws_subnet.kpmgprv.id]
  security_groups    = ["sg-edcd9784", "sg-edcd9785"]

  access_logs = {
    bucket = "kpmgalblogs"
  }

  target_groups = [
    {
      name_prefix      = "pref-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    customer = var.client_name
  }
}