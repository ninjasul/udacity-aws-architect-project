# TODO: Designate a cloud provider, region, and credentials
variable "region" {
  default = "ap-northeast-2"
}

provider "aws" {
  region = var.region
  alias  = "default-provider"
}

resource "aws_key_pair" "my-key" {
  provider   = aws.default-provider
  key_name   = "my-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# TODO: provision 4 AWS t2.micro EC2 instances named Udacity T2
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.default-provider
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

variable "instance-type-t2-micro" {
  type    = string
  default = "t2.micro"
}

resource "aws_instance" "UdacityT2" {
  count         = 4
  provider      = aws.default-provider
  ami           = data.aws_ssm_parameter.linuxAmi.value
  instance_type = var.instance-type-t2-micro
  key_name      = aws_key_pair.my-key.key_name
  tags = {
    Name = "UdacityT2-${count.index + 1}"
  }
}


# TODO: provision 2 m4.large EC2 instances named Udacity M4
variable "instance-type-m4-large" {
  type    = string
  default = "m4.large"
}

resource "aws_instance" "UdacityM4" {
  count         = 2
  provider      = aws.default-provider
  ami           = data.aws_ssm_parameter.linuxAmi.value
  instance_type = var.instance-type-m4-large
  key_name      = aws_key_pair.my-key.key_name
  tags = {
    Name = "UdacityM4-${count.index + 1}"
  }
}