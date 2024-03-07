resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "VPC"
    }
}

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

resource "aws_internet_gateway" "IGW" {
    vpc_id = aws_vpc.vpc.id

    tags = {
      Name = "IGW"
    }
}

resource "aws_eip" "NAT-a" {
    vpc = true

    lifecycle {
      create_before_destroy = true 
    } 
}

resource "aws_nat_gateway" "nat_gateway-a" {
    allocation_id = aws_eip.NAT-a.id 
    subnet_id = aws_subnet.public_subnet_a.id 
    tags = {
      Name = "NAT-GW-b"
    }  
}

resource "aws_eip" "NAT-b" {
    vpc = true

    lifecycle {
      create_before_destroy = true 
    } 
}

resource "aws_nat_gateway" "nat_gateway-b" {
    allocation_id = aws_eip.NAT-b.id 
    subnet_id = aws_subnet.public_subnet_b.id 
    tags = {
      Name = "NAT-GW-b"
    }  
}

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

resource "aws_route" "nat-a" {
  route_table_id         = aws_route_table.private_rt-a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway-a.id
}

resource "aws_route" "nat-b" {
  route_table_id         = aws_route_table.private_rt-b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gateway-b.id
}

data "http" "myip" {
  url = "https://ifconfig.me/ip"
  }

resource "aws_security_group" "bastion-ec2" {
  name = "bastion-sg"
  description = "bastion-sg"
  vpc_id = aws_vpc.vpc.id   

  ingress {
    from_port = 22 
    to_port = 22 
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    }

 egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    }

  tags = {
    Name = "bastion-sg"
    }
}

resource "aws_security_group" "private1-sg" {
  name = "private1-sg"
  description = "private1-sg"
  vpc_id = aws_vpc.vpc.id   


  ingress {
    from_port = 22 
    to_port = 22 
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private1-sg"
  }
}

resource "aws_security_group_rule" "inbound_http_1" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp" 
  source_security_group_id = aws_security_group.elb-sg.id
  security_group_id = aws_security_group.private1-sg.id
}

resource "aws_security_group" "private2-sg" {
  name = "private2-sg"
  description = "private2-sg"
  vpc_id = aws_vpc.vpc.id   

  ingress {
    from_port = 22 
    to_port = 22 
    protocol = "tcp"
  }
  
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private2-sg"
  }
}

resource "aws_security_group_rule" "inbound_http_2" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp" 
  source_security_group_id = aws_security_group.elb-sg.id
  security_group_id = aws_security_group.private2-sg.id
}

resource "aws_security_group" "elb-sg" {
  name = "elb-sg"
  description = "elb-sg"
  vpc_id = aws_vpc.vpc.id   
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "elb-sg"
  }
}

resource "aws_instance" "bastion" {
    ami = "ami-0bfd23bc25c60d5a1"
    instance_type = "t3.small"
    subnet_id = aws_subnet.public_subnet_a.id
    vpc_security_group_ids = [aws_security_group.bastion-ec2.id]
    user_data = <<EOF
#!/bin/bash
sudo yum install -y httpd
sudo systemctl enable --now httpd
sudo echo 'bastion' > /var/www/html/index.html 
sudo systemctl restart httpd
EOF
    
    tags = {
        Name = "bastion"
    }
} 

resource "aws_instance" "private-instance-a" {
    ami = "ami-0bfd23bc25c60d5a1"
    instance_type = "t3.small"
    subnet_id = aws_subnet.private_subnet_a.id
    vpc_security_group_ids = [aws_security_group.private1-sg.id]
    user_data = <<EOF
#!/bin/bash
sudo yum install -y httpd
sudo systemctl enable --now httpd
sudo echo "private-instance-a" > /var/www/html/index.html 
sudo systemctl restart httpd
EOF

    tags = {
        Name = "private-instance-a"
    }
} 

resource "aws_instance" "private-instance-b" {
    ami = "ami-0bfd23bc25c60d5a1"
    instance_type = "t3.small"
    subnet_id = aws_subnet.private_subnet_b.id
    vpc_security_group_ids = [aws_security_group.private2-sg.id]
    user_data = <<EOF
#!/bin/bash
sudo yum install -y httpd
sudo systemctl enable --now httpd
sudo echo "private-instance-b" > /var/www/html/index.html 
sudo systemctl restart httpd
EOF

    tags = {
        Name = "private-instance-b"
    }
} 

resource "aws_lb" "alb" {
    name = "alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.elb-sg.id]
    subnets = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    tags = {
        Name = "alb"
    }
}

resource "aws_lb_target_group" "alb-tg" {
    name = "alb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc.id
    target_type = "instance"
}

resource "aws_lb_listener" "alb-listener" {
    load_balancer_arn = aws_lb.alb.arn 
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb-tg.arn
    }  
}

resource "aws_lb_target_group_attachment" "internal-alb-attach-resource_1" {
    target_group_arn = aws_lb_target_group.alb-tg.arn 
    target_id = aws_instance.private-instance-b.id 
    port = 80 
    depends_on = [aws_lb_listener.alb-listener]
}

resource "aws_lb_target_group_attachment" "internal-alb-attach-resource_2" {
    target_group_arn = aws_lb_target_group.alb-tg.arn 
    target_id = aws_instance.private-instance-a.id 
    port = 80 
    depends_on = [aws_lb_listener.alb-listener]
}