
variable "ami_prefix" {
  type    = string
  default = "amazon-linux-2-arm"
}

variable "app_name" {
  type    = string
  default = "vault"
}

variable "deployment_version" {
  type    = string
  default = "version-1"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami_owner" {
  type    = string
  default = "amazon"
}

variable "ssh_username" {
  type    = string
  default = "ec2-user"
}

variable "subnet_id" {
  type    = string
  default = "subnet-056dfefxxxxxxxx"
}

variable "vault_version" {
  type    = string
  default = "1.7.3"
}

variable "vpc_id" {
  type    = string
  default = "vpc-06626bb5xxxxxxx"
}

# timestamp()函数 获取当前时间，并用 regex_replace() 移除 -、空格等，使其格式化为一个紧凑的字符串（如 20240311123045）。
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

locals {
  ami_name = "${var.ami_prefix}-${var.app_name}-ent-${local.timestamp}"
}
/*
  用于在 Packer 模板内部 动态获取或计算数据，然后可以在 locals 或 sources 配置中使用这些数据
  用于查找 Amazon 官方提供的 最新的 Amazon Linux 2 ARM64 AMI。
  root-device-type = "ebs"：只选择基于 EBS 的 AMI（非 instance-store）
  virtualization-type = "hvm"：选择 HVM（硬件虚拟化）类型的 AMI。
  most_recent = true：获取最新版本的 AMI。
  owners = ["amazon"]：确保 AMI 来自 Amazon 官方账户。
*/

data "amazon-ami" "amazon-linux-2-arm" {
  filters = {
    name                = "amzn2-ami-hvm-2.*-arm64-gp2"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = var.region
}

source "amazon-ebs" "vault-node" {
  ami_name      = local.ami_name
  ami_regions   = ["us-east-1", "us-east-2"]
  instance_type = "t4g.small"
  region        = var.region
  source_ami    = data.amazon-ami.amazon-linux-2-arm.id
  ssh_username  = var.ssh_username
  subnet_id     = var.subnet_id
  tags = {
    Name = local.ami_name
    Vault_Version = var.vault_version
  }
  vpc_id = var.vpc_id
}

build {
  sources = ["source.amazon-ebs.vault-node"]

  provisioner "file" {
    destination = "/tmp"
    source      = "files"
  }

  provisioner "shell" {
    environment_vars = ["VAULT_VERSION=${var.vault_version}+ent"]
    script           = "scripts/setup.sh"
  }

  provisioner "shell" {
    inline = ["echo ${var.deployment_version} > ~/DEPLOYMENT_VERSION"]
  }
# Add a manifest so it can be parsed by the ami-share job
 post-processor "manifest" {}
}