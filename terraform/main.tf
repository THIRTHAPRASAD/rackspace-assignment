terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Creating a New Key
resource "aws_key_pair" "Key-Pair" {

  # Name of the Key
  key_name = "MyKey"

  # Adding the SSH authorized key !
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2JATOXdmQNsvtAwHgobCE+94X25v5XIefY3vtYgQKEGBH4kBigvz8PV5lRLHt7/OLywqXHM07UGSGPxqbw1Lh21f7rVSZo7Q5wnmdQOo6aSzhkz/Lm8JGtS9nbxcSU1IDqMHskqoc3d0MKyBRY5wf7I/r5hAtGcA4QZ4mUe5d9jD7F1JEX5bgE6otrXSv3QKseRiTGNKpvhDoCb9uU/AmOOTZO/Uf5nazsCuUtrvg0GylAmVxUxCKMl5wLQdS+gdZmkIGtJA0gg2r4vU8Hv/bf9VtHFT/DCVDkgoIwC2D8RdO5epkHODllR9qk5JmtkC0K7AceCsxy3C+EhwXKfolxBeVKu8+Etud8k8/b8u3NXCMjLaIcjCbZi1hwwJHz4T36/C7mjyaArTzX8aNlio5i9MVNKjdYwGz25n9/+x1VGdW1U6HVwgg5EmaeTm7mEQ9jBHAL485H8BAUSUd501CT6ncgiIjSu4JRsj80OQrlTLDAA+O68gEgWVdzkqb8v0= rajender@raj"

}


# Creating a VPC!
resource "aws_vpc" "rack" {

  # IP Range for the VPC
  cidr_block = "172.20.0.0/16"

  # Enabling automatic hostname assigning
  enable_dns_hostnames = true
  tags = {
    Name = "rack"
  }
}


# Creating Public subnet!
resource "aws_subnet" "subnet1" {
  depends_on = [
    aws_vpc.rack
  ]

  # VPC in which subnet has to be created!
  vpc_id = aws_vpc.rack.id

  # IP Range of this subnet
  cidr_block = "172.20.10.0/24"

  # Data Center of this subnet.
  availability_zone = "us-east-1a"

  # Enabling automatic public IP assignment on instance launch!
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}


# Creating an Internet Gateway for the VPC
resource "aws_internet_gateway" "Internet_Gateway" {
  depends_on = [
    aws_vpc.rack,
    aws_subnet.subnet1
  ]

  # VPC in which it has to be created!
  vpc_id = aws_vpc.rack.id

  tags = {
    Name = "IG-Public-&-Private-VPC"
  }
}

# Creating an Route Table for the public subnet!
resource "aws_route_table" "Public-Subnet-RT" {
  depends_on = [
    aws_vpc.rack,
    aws_internet_gateway.Internet_Gateway
  ]

  # VPC ID
  vpc_id = aws_vpc.rack.id

  # NAT Rule
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Internet_Gateway.id
  }

  tags = {
    Name = "Route Table for Internet Gateway"
  }
}

# Creating a resource for the Route Table Association!
resource "aws_route_table_association" "RT-IG-Association" {

  depends_on = [
    aws_vpc.rack,
    aws_subnet.subnet1,
    aws_route_table.Public-Subnet-RT
  ]

  # Public Subnet ID
  subnet_id = aws_subnet.subnet1.id

  #  Route Table ID
  route_table_id = aws_route_table.Public-Subnet-RT.id
}

# Creating a Security Group for WordPress
resource "aws_security_group" "JENKINS-SG" {

  depends_on = [
    aws_vpc.rack,
    aws_subnet.subnet1,
    
  ]

  description = "HTTP, PING, SSH"

  # Name of the security Group!
  name = "jenkins-sg"

  # VPC ID in which Security group has to be created!
  vpc_id = aws_vpc.rack.id

  # Created an inbound rule for webserver access!
  ingress {
    description = "HTTP for webserver"
    from_port   = 8001
    to_port     = 8001

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP for webserver"
    from_port   = 8000
    to_port     = 8000

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP for webserver"
    from_port   = 3306
    to_port     = 3306

    # Here adding tcp instead of http, because http in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Created an inbound rule for ping
  ingress {
    description = "Ping"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Created an inbound rule for SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22

    # Here adding tcp instead of ssh, because ssh in part of tcp only!
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic for the WordPress
  egress {
    description = "output from webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# Creating an AWS instance for the Jenkins!
resource "aws_instance" "jenkins" {

  depends_on = [
    aws_vpc.rack,
    aws_subnet.subnet1,
  ]

  ami           = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet1.id

  # Keyname and security group are obtained from the reference of their instances created above!
  # Here I am providing the name of the key which is already uploaded on the AWS console.
  key_name = "MyKey"

  # Security groups to use!
  vpc_security_group_ids = [aws_security_group.JENKINS-SG.id]

}
