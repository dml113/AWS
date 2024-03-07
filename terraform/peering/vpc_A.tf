resource "aws_vpc" "vpc_A" {
    cidr_block = "10.2.0.0/16"

    tags = {
        Name = "VPC_A"
    }
}

resource "aws_subnet" "VPC_A_public_subnet_a" {
    vpc_id = aws_vpc.vpc_A.id
    cidr_block = "10.2.0.0/24"
    availability_zone = "us-east-1a"
    
    map_public_ip_on_launch = true

    tags = {
        Name = "VPC_A_public_subnet_a"
    }
}

resource "aws_subnet" "VPC_A_private_subnet_a" {
    vpc_id = aws_vpc.vpc_A.id
    cidr_block = "10.2.2.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "VPC_A_private_subnet_a"
    }
}

resource "aws_internet_gateway" "VPC_A_IGW" {
    vpc_id = aws_vpc.vpc_A.id

    tags = {
      Name = "VPC_A_IGW"
    }
}

resource "aws_eip" "VPC_A_EIP" {
    vpc = true

    lifecycle {
      create_before_destroy = true 
    } 
}

resource "aws_nat_gateway" "VPC_A_nat_gateway-a" {
    allocation_id = aws_eip.VPC_A_EIP.id 
    subnet_id = aws_subnet.VPC_A_public_subnet_a.id 
    tags = {
      Name = "VPC_A_NAT-GW-b"
    }  
}

resource "aws_route_table" "VPC_A_public_rt" {
    vpc_id = aws_vpc.vpc_A.id 

    tags = {
      Name = "VPC_A_public-rt"
    }  
}

resource "aws_route_table_association" "VPC_A_public_route_table_association_1" {
    subnet_id = aws_subnet.VPC_A_public_subnet_a.id
    route_table_id = aws_route_table.VPC_A_public_rt.id 
}

resource "aws_route_table" "VPC_A_private_rt-a" {
    vpc_id = aws_vpc.vpc_A.id 

    tags = {
      Name = "VPC_A_private_rt-a"
    }  
}

resource "aws_route_table_association" "VPC_A_private_route_table_association_1" {
    subnet_id = aws_subnet.VPC_A_private_subnet_a.id
    route_table_id = aws_route_table.VPC_A_private_rt-a.id
}


resource "aws_route" "VPC_A_igw-connect" {
  route_table_id         = aws_route_table.VPC_A_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.VPC_A_IGW.id
}

resource "aws_route" "VPC_A_nat-a" {
  route_table_id         = aws_route_table.VPC_A_private_rt-a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.VPC_A_nat_gateway-a.id
}