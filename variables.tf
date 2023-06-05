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
  default = 3
}

variable "instance_names" {
  default = ["ansible-host", "ansible-1", "ansible-2"]
}

variable "keypair" {
  description = "Adding the SSH authorized key"
  type        = string
  default     = "tf-deploy"
}

# base_path for refrencing 
variable "base_path" {
  description = "local file path"
  default     = "./private-key"
}
