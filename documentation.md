## Provision EC2 Instances With Terraform And Deploy Web Page with Ansible
This is a basic project to get familiar with terraform and ansible.

## Project Steps:
- <a href=" ">Install And Configure Terraform On Local System</a>
- <a href=" ">Install IDE for Terraform — VS Code Editor</a>


## Install And Configure Terraform On Local System
Download Terraform: https://www.terraform.io/downloads.html

```

# Copy binary zip file to a folder
mkdir /Users/<YOUR-USER>/Documents/terraform-install
COPY Package to "terraform-install" folder

# Unzip
unzip <PACKAGE-NAME>
unzip terraform_0.14.3_darwin_amd64.zip

# Copy terraform binary to /usr/local/bin
echo $PATH
mv terraform /usr/local/bin

# Verify Version
terraform version

# To Uninstall Terraform (NOT REQUIRED)
rm -rf /usr/local/bin/terraform

```

<br>

<br>

## Install IDE for Terraform — VS Code Editor

[Microsoft Visual Studio Code Editor](https://code.visualstudio.com/download)

[Hashicorp Terraform Plugin for VS Code](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)


<br>

<br>

## use your IAM credentials to authenticate the Terraform AWS provider

In AWS Cli set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` variables

```

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

```

<br>

## Create a new Terraform configuration file
We will provision the following:
- Key pair
- security group
- 3 instances: an ansible host and 2 servers
- an elastic ip that will be attached to the ansible host

<br>

<br>

- create a folder named: `terraform-ansible`
- in `terraform-ansible` create a new file `main.tf` and add the following to create 3 instances:

```

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


# Launch Instances on Amazon Linux 2 Kernel 5.10
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



```

<br>

<br>

<img width="907" alt="main" src="https://github.com/earchibong/terraform-ansible/assets/92983658/a0322909-0c39-4467-9a5a-07e3c9cac8fb">

<br>

<br>


## Create A `variables` file
- create a file named `variables.tf` and add the following:

```

variable "aws_region" {
  type = string
  default = "eu-west-2"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "instance_count" {
  type = number
  default = 2
}



```

<br>

<br>

<img width="911" alt="variables" src="https://github.com/earchibong/terraform-ansible/assets/92983658/fa4d6487-345c-4009-b095-3e195f2bf5a9">

<br>

<br>


## Create a `versions` file
- create a file named `versions.tf`

```

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20"
    }
  }
}

```

<br>

<br>

## Terraform Init, Plan And Apply
```

terraform init
terraform plan -var 'instance_count=3'
terraform apply -var 'instance_count=3'


```

<br>

<br>

The `plan` command will show you the changes that will be made, and the `apply` command will create the instances. You can adjust the `instance_count` variable to launch more or fewer instances as needed.

<br>

<br>

## Install And Configure Ansible in Host server
- ssh into the `ansible host` server

<br>

```

sudo yum update
sudo amazon-linux-extras install ansible2

```

<br>

<br>

- copy private key `tf-deploy.pem` from local enivronment into `ansible-host` server

```

sudo scp -i “tf-deploy.pem” tf-deploy <<public DNS of EC2>>:/home/ubuntu/.ssh

```

<br>

<br>

- Create a directory and name it `ansible/playbooks` – it will be used to store all your playbook files: `playbooks`
- Create a directory and name it `ansible/inventory` – it will be used to keep your hosts organised.: `inventory`
- Within the playbooks folder, create your first playbook, and name it `playbook.yml`: `touch playbooks/playbook.yaml`
- Within the inventory folder, create an inventory file (.yml) for each environment (Development, Staging Testing and Production) `dev`, `staging`, `uat`, and `prod` respectively.

<br>

<br>

<img width="806" alt="playbook-inventory" src="https://github.com/earchibong/terraform-ansible/assets/92983658/417d1761-66a0-4f57-9d42-68be4a80ec2c">

<br>

<br>

### Set Up Ansible Inventory
- exit `ansible-host` server
- Set up an SSH agent and connect to `ansible-host` server:

<br>
```

# on your local machine:

eval `ssh-agent -s`
ssh-add ./<path-to-private-key>

# Confirm the key has been added:
ssh-add -l


# ssh into Jenkins-Ansible server using ssh-agent: 
ssh -A -i "private ec2 key" ec2-user@public_ip


```

<br>

<br>

<img width="1244" alt="ssh-agent" src="https://github.com/earchibong/terraform-ansible/assets/92983658/04c73171-2388-499b-9640-f76139f24aa1">

<br>

<br>

- Update inventory/dev.yml file with this snippet of code: *notice that the user in this case is `ec2-user` for an ubuntu server it would be `ubuntu`*

```

[webservers]
<Web-Server1-Private-IP-Address> ansible_ssh_user='ec2-user'
<Web-Server2-Private-IP-Address> ansible_ssh_user='ec2-user'

```

<br>

<br>

<img width="785" alt="inventory" src="https://github.com/earchibong/terraform-ansible/assets/92983658/b61f1a98-cc27-4103-bf64-cfd8f9a0dbe6">

<br>

<br>

- ping all servers

```

ansible all -m ping

```

<br>

## Create a playbook
