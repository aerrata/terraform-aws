locals {
  name_prefix = "${var.environment}-${var.project_name}"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name = "${local.name_prefix}-vpc"
    },
    var.tags
  )
}

resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "${local.name_prefix}-${each.key}"
      Tier = "public"
    },
    var.tags
  )
}

resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name = "${local.name_prefix}-${each.key}"
      Tier = "private"
    },
    var.tags
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.name_prefix}-igw"
    },
    var.tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.name_prefix}-public-rt"
    },
    var.tags
  )
}

resource "aws_route_table" "private" {
  for_each = var.private_subnets

  vpc_id = aws_vpc.main.id
  tags = merge(
    {
      Name = "${local.name_prefix}-private-rt-${split("-", each.key)[0]}-${split("-", each.key)[1]}"
    },
    var.tags
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "nat_gateway" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main["public-${split("-", each.key)[1]}"].id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  domain   = "vpc"

  tags = merge(
    {
      Name = "${local.name_prefix}-nat-eip-${each.key}"
    },
    var.tags
  )
}

resource "aws_nat_gateway" "main" {
  for_each          = aws_subnet.public
  allocation_id     = aws_eip.nat[each.key].id
  subnet_id         = each.value.id
  connectivity_type = "public"
  depends_on        = [aws_internet_gateway.main]

  tags = merge(
    {
      Name = "${local.name_prefix}-nat-${each.key}"
    },
    var.tags
  )
}

resource "aws_security_group" "global" {
  name        = "${local.name_prefix}-global-sg"
  description = "Allow inbound connection only from within VPC network"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.name_prefix}-global-sg"
    },
    var.tags
  )

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }
}

resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.name_prefix}-bastion-sg"
    },
    var.tags
  )

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow HTTP inbound traffic from CloudFront"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    {
      Name = "${local.name_prefix}-alb-sg"
    },
    var.tags
  )

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }
}
