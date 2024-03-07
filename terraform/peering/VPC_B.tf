resource "aws_vpc" "vpc_B" {
    cidr_block = "10.4.0.0/16"

    tags = {
        Name = "VPC_B"
    }
}

resource "aws_subnet" "VPC_B_public_subnet_a" {
    vpc_id = aws_vpc.vpc_B.id
    cidr_block = "10.4.0.0/24"
    availability_zone = "us-east-1a"
    
    map_public_ip_on_launch = true

    tags = {
        Name = "VPC_B_public_subnet_a"
    }
}

resource "aws_subnet" "VPC_B_private_subnet_a" {
    vpc_id = aws_vpc.vpc_B.id
    cidr_block = "10.4.2.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "VPC_B_private_subnet_a"
    }
}

resource "aws_subnet" "VPC_B_private_subnet_b" {
    vpc_id = aws_vpc.vpc_B.id
    cidr_block = "10.4.1.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "VPC_B_private_subnet_b"
    }
}

resource "aws_internet_gateway" "VPC_B_IGW" {
    vpc_id = aws_vpc.vpc_B.id

    tags = {
      Name = "VPC_B_IGW"
    }
}

resource "aws_eip" "VPC_B_EIP" {
    vpc = true

    lifecycle {
      create_before_destroy = true 
    } 
}

resource "aws_nat_gateway" "VPC_B_nat_gateway-a" {
    allocation_id = aws_eip.VPC_B_EIP.id 
    subnet_id = aws_subnet.VPC_B_public_subnet_a.id 
    tags = {
      Name = "VPC_B_NAT-GW-b"
    }  
}

resource "aws_route_table" "VPC_B_public_rt" {
    vpc_id = aws_vpc.vpc_B.id 

    tags = {
      Name = "VPC_B_public-rt"
    }  
}

resource "aws_route_table_association" "VPC_B_public_route_table_association_1" {
    subnet_id = aws_subnet.VPC_B_public_subnet_a.id
    route_table_id = aws_route_table.VPC_B_public_rt.id 
}

resource "aws_route_table" "VPC_B_private_rt-a" {
    vpc_id = aws_vpc.vpc_B.id 

    tags = {
      Name = "VPC_B_private_rt-a"
    }  
}

resource "aws_route_table_association" "VPC_B_private_route_table_association_1" {
    subnet_id = aws_subnet.VPC_B_private_subnet_a.id
    route_table_id = aws_route_table.VPC_B_private_rt-a.id
}

resource "aws_route_table_association" "VPC_B_private_route_table_association_2" {
    subnet_id = aws_subnet.VPC_B_private_subnet_b.id
    route_table_id = aws_route_table.VPC_B_private_rt-a.id
}

resource "aws_route" "VPC_B_igw-connect" {
  route_table_id         = aws_route_table.VPC_B_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.VPC_B_IGW.id
}

resource "aws_route" "VPC_B_nat-a" {
  route_table_id         = aws_route_table.VPC_B_private_rt-a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.VPC_B_nat_gateway-a.id
}