#######################################
#               VPC                   #
#######################################
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "VPC"
    }
}

#######################################
#               subnet                #
#######################################
resource "aws_subnet" "public_subnet_a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-northeast-2a"
    
    map_public_ip_on_launch = true

    tags = {
        Name = "public_subnet_a"
    }
}

resource "aws_subnet" "public_subnet_b" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-2b"
    
    map_public_ip_on_launch = true

    tags = {
        Name = "public_subnet_b"
    }
}

resource "aws_subnet" "private_subnet_a" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-northeast-2a"
    tags = {
        Name = "private_subnet_a"
    }
}

resource "aws_subnet" "private_subnet_b" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-northeast-2b"
    tags = {
        Name = "private_subnet_b"
    }
}
#######################################
#               gateway               #
#######################################
resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name = "IGW"
    }
}

resource "aws_eip" "nat-eip1" {
    vpc = true

    lifecycle {
      create_before_destroy = true 
    } 
}

resource "aws_nat_gateway" "nat_gateway-a" {
    allocation_id = aws_eip.nat-eip1.id 
    subnet_id = aws_subnet.public_subnet_a.id 
    tags = {
      Name = "NAT-GW-b"
    }  
}

resource "aws_eip" "nat-eip2" {
    vpc = true

    lifecycle {
      create_before_destroy = true 
    } 
}

resource "aws_nat_gateway" "nat_gateway-b" {
    allocation_id = aws_eip.nat-eip2.id 
    subnet_id = aws_subnet.public_subnet_b.id 
    tags = {
      Name = "NAT-GW-b"
    }  
}

#######################################
#               route                 #
#######################################
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
      Name = "public-rt"
    }  
}

resource "aws_route_table_association" "public_route_table_association_1" {
    subnet_id = aws_subnet.public_subnet_a.id
    route_table_id = aws_route_table.public_rt.id 
}

resource "aws_route_table_association" "public_route_table_association_2" {
    subnet_id = aws_subnet.public_subnet_b.id
    route_table_id = aws_route_table.public_rt.id 
}

resource "aws_route_table" "private_rt-a" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
      Name = "private_rt-a"
    }  
}

resource "aws_route_table_association" "private_route_table_association_1" {
    subnet_id = aws_subnet.private_subnet_a.id
    route_table_id = aws_route_table.private_rt-a.id
}

resource "aws_route_table" "private_rt-b" {
    vpc_id = aws_vpc.vpc.id 

    tags = {
      Name = "private_rt-b"
    }  
}

resource "aws_route_table_association" "private_route_table_association_2" {
    subnet_id = aws_subnet.private_subnet_b.id
    route_table_id = aws_route_table.private_rt-b.id
}


resource "aws_route" "igw-connect" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.IGW.id
}

resource "aws_route" "nat-a-connect" {
  route_table_id         = aws_route_table.private_rt-a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway-a.id
}

resource "aws_route" "nat-b-connect" {
  route_table_id         = aws_route_table.private_rt-b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway-b.id
}
