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
- create a folder named: `terraform-ansible`
- in `terraform-ansible` create a new file `main.tf` and add the following to create 3 instances:

```

provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "ec2_instances" {
  count         = var.instance_count
  ami           = "ami-0a6006bac3b9bb8d3"
  instance_type = var.instance_type

  tags = {
    Name = "EC2 Instance ${count.index}"
  }
}



```

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

