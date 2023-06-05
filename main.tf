provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

# Private Key and Keypair
## Create a key with RSA algorithm with 4096 rsa bits
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

## Create a key pair using above private key
resource "aws_key_pair" "keypair" {

  # Name of the Key
  key_name = var.keypair

  public_key = tls_private_key.private_key.public_key_openssh
  depends_on = [tls_private_key.private_key]
}

## Save the private key at the specified path
resource "local_file" "save-key" {
  content  = tls_private_key.private_key.private_key_pem
  filename = "${var.base_path}/${var.keypair}.pem"
}


# Create a Security Group for the WordPress instance, so that anyone in the outside world can access the instance by HTTP, PING, SSH
resource "aws_security_group" "ansible-sg" {

  # Name of the webserver security group
  name        = "ansible-sg"
  description = "Allow outside world to access the instance via HTTP, PING, SSH"

  # VPC ID in which Security group has to be created!
  vpc_id = data.aws_vpc.default.id

  # Create an inbound rule for webserver HTTP access
  ingress {
    description = "HTTP to Webserver"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Create an inbound rule for PING
  ingress {
    description = "PING to Webserver"
    from_port   = 0
    to_port     = 0
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Create an inbound rule for SSH access
  ingress {
    description = "SSH to Webserver"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    ##security_groups = [aws_security_group.bastion-sg.id]
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outward Network Traffic from the WordPress webserver
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Ansible Security Group"
  }
}


resource "aws_instance" "ec2_instances" {
  count         = var.instance_count
  ami           = "ami-0a6006bac3b9bb8d3"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.ansible-sg.id]
  key_name = "tf-deploy"

  tags = {
    Name = "${element(var.instance_names, count.index)}"
  }
}



resource "aws_eip" "ansible-host" {
  domain      = "vpc"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.ec2_instances[0].id
  allocation_id = aws_eip.ansible-host.id
}