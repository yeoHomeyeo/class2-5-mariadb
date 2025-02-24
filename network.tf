
#super basic vpc with no gateway and created to cater only for a private subnet
resource "aws_vpc" "chrisy-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "chrisy-vpc"
  }
}

resource "aws_subnet" "chrisy_private_subnet_a" {
  vpc_id            = aws_vpc.chrisy-vpc.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "chrisy-private-subnet"
  }
}
resource "aws_subnet" "chrisy_private_subnet_b" {
  vpc_id            = aws_vpc.chrisy-vpc.id
  cidr_block        = "10.0.103.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "chrisy-private-subnet"
  }
}

resource "aws_subnet" "chrisy_public_subnet_a" {
  vpc_id                  = aws_vpc.chrisy-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "chrisy-public-subnet"
  }
}

resource "aws_subnet" "chrisy_public_subnet_b" {
  vpc_id                  = aws_vpc.chrisy-vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "chrisy-public-subnet"
  }
}

data "aws_ami" "linux2023" {
  most_recent = true
  filter {
    name   = "name"
    values = ["al2023-ami-2023*x86_64"]
  }
}

resource "aws_instance" "chrisy_maria_ec2" {
  ami           = data.aws_ami.linux2023.id
  instance_type = "t2.micro" # Choose an instance type

  subnet_id              = aws_subnet.chrisy_public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  #vpc_security_group_ids = [aws_security_group.chrisy_vpc_db_secgrp.id]  #place this ec2 on the same sec group as the RDS instance

  key_name = "chrisy-15feb25-keypair" # Replace with your key pair name (optional but recommended)

  user_data = <<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install mariadb105 -y
              EOF

  tags = {
    Name = "chrisy mariadb ec2 class2-5"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "chrisy_igw" {
  vpc_id = aws_vpc.chrisy-vpc.id
  tags = {
    Name = "chrisy-igw"
  }
}

# Public Route Table
resource "aws_route_table" "chrisy_public_rt" {
  vpc_id = aws_vpc.chrisy-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.chrisy_igw.id
  }
  tags = {
    Name = "chrisy-public-rt"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "chrisy_public_rta_a" {
  subnet_id      = aws_subnet.chrisy_public_subnet_a.id
  route_table_id = aws_route_table.chrisy_public_rt.id
}

resource "aws_route_table_association" "chrisy_public_rta_b" {
  subnet_id      = aws_subnet.chrisy_public_subnet_b.id
  route_table_id = aws_route_table.chrisy_public_rt.id
}

# Private Route Table
resource "aws_route_table" "chrisy_private_rt" {
  vpc_id = aws_vpc.chrisy-vpc.id
  tags = {
    Name = "chrisy-private-rt"
  }
}

# Private Route Table Association
resource "aws_route_table_association" "chrisy_private_rta_a" {
  subnet_id      = aws_subnet.chrisy_private_subnet_a.id
  route_table_id = aws_route_table.chrisy_private_rt.id
}

resource "aws_route_table_association" "chrisy_private_rta_b" {
  subnet_id      = aws_subnet.chrisy_private_subnet_b.id
  route_table_id = aws_route_table.chrisy_private_rt.id
}


resource "aws_security_group" "allow_ssh" {
  name        = "chrisy-security-group-ssh"
  description = "Allow SSH inbound"
  vpc_id      = aws_vpc.chrisy-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this in production!
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this in production!
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this in production!
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict this in production!
  }

  egress { # Add this egress block!
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allow all outbound protocols
    cidr_blocks = ["0.0.0.0/0"] # Restrict this in production!
  }
}
