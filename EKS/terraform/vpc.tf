#
# Create VPC 
#
  resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "doc-vpc"
  }
 }

#
# Create Public_Subnet 
#
  resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"
 
  map_public_ip_on_launch = true

  tags = {
    Name = "doc-pub-sn-a"
  }
 }

  resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2b"
 
  map_public_ip_on_launch = true

  tags = {
    Name = "doc-pub-sn-b"
  }
 }
 
#
# Create private-subnet 
#
  resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "doc-priv-sn-a"
  }
 }

  resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "doc-priv-sn-b"
  }
 }

#
# Create protected-subnet 
#
resource "aws_subnet" "protected_subnet_a" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "doc-pro-sn-a"
  }
 }

  resource "aws_subnet" "protected_subnet_b" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "doc-pro-sn-b"
  }
 }

#
# Create Internet_Gateway 
#
  resource "aws_internet_gateway" "igw" {
  vpc_id     = aws_vpc.vpc.id
  
  tags = {
    Name = "doc-igw"
  }
 }

#
# Create EIP
#
  resource "aws_eip" "eip_a" {
  domain   = "vpc"

  tags = {
    Name = "doc-eip-a"
  }
 }

  resource "aws_eip" "eip_b" {
  domain   = "vpc"

  tags = {
    Name = "doc-eip-b"
  }
 }

#
# Create Nat_Gateway
#
  resource "aws_nat_gateway" "natgw_a" {
  allocation_id = aws_eip.eip_a.id
  subnet_id     = aws_subnet.public_subnet_a.id
  
  tags = {
    Name = "doc-natgw-a"
  }
 }

  resource "aws_nat_gateway" "natgw_b" {
  allocation_id = aws_eip.eip_b.id
  subnet_id     = aws_subnet.public_subnet_b.id
  
  tags = {
    Name = "doc-natgw-b"
  }
 }

#
# Create Public_Route_Table
#
  resource "aws_route_table" "public_rt" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "doc-public-rt"
  }
 }

  resource "aws_route_table_association" "public_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

  resource "aws_route_table_association" "public_association_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

#
# Create Private_Route_Table
#
  resource "aws_route_table" "private_rt_a" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw_a.id
  }
  
  tags = {
    Name = "doc-private-rt-a"
  }
 }

  resource "aws_route_table_association" "private_association_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

  resource "aws_route_table" "private_rt_b" {
  vpc_id     = aws_vpc.vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.natgw_b.id
  }
  
  tags = {
    Name = "doc-private-rt-b"
  }
 }

 resource "aws_route_table_association" "private_association_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

#
# Create Protected_Route_Table
#
  resource "aws_route_table" "protected_rt" {
  vpc_id     = aws_vpc.vpc.id
  
  tags = {
    Name = "doc-protected-rt"
  }
 }

  resource "aws_route_table_association" "protected_association_a" {
  subnet_id      = aws_subnet.protected_subnet_a.id
  route_table_id = aws_route_table.protected_rt.id
}

 resource "aws_route_table_association" "protected_association_b" {
  subnet_id      = aws_subnet.protected_subnet_b.id
  route_table_id = aws_route_table.protected_rt.id
}
