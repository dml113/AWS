#
# Create Key-pair
#
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = "bastion-keypair.pem"
  public_key = tls_private_key.bastion_key.public_key_openssh
} 

resource "local_file" "bastion_local" {
  filename        = "park.pem"
  content         = tls_private_key.bastion_key.private_key_pem
}


#
# Create Security_Group
#
  resource "aws_security_group" "Bastion_Instance_SG" {
  name        = "doc-bastion-ec2-sg"
  description = "doc-bastion-ec2-sg"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name = "doc-bastion-ec2-sg"
  }
}

#
# Create Security_Group_Rule
#
  data "http" "myip" {
    url = "http://ipv4.icanhazip.com"
}

  resource "aws_security_group_rule" "Bastion_Instance_SG_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
}
  resource "aws_security_group_rule" "Bastion_Instance_SG_egress" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
}
  resource "aws_security_group_rule" "Bastion_Instance_SG_egress2" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.Bastion_Instance_SG.id}"
}

#
# Create Bastion_Instance
#
  resource "aws_instance" "Bastion_Instance" {
  subnet_id     = aws_subnet.public_subnet_a.id
  security_groups = [aws_security_group.Bastion_Instance_SG.id]
  ami           = "ami-01123b84e2a4fba05" #amazonlinux2023
  instance_type = "t3.medium"
  key_name = "bastion-keypair.pem"
  user_data = <<EOF
#!/bin/bash
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
echo 'Skill53##' | passwd --stdin ec2-user
EOF

  tags = {
    Name = "doc-bastion-ec2"
  }
}
