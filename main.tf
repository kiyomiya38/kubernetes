provider "aws" {
  region = var.aws_region
}

variable "instance_names" {
  default = ["workstation", "cp1", "cp2", "cp3", "worker1", "worker2"]
}

# Workstation用のSSH鍵を生成
resource "tls_private_key" "workstation_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Workstation以外のインスタンスを作成
resource "aws_instance" "example" {
  for_each = setsubtract(toset(var.instance_names), toset(["workstation"])) # Workstationを除外
  ami      = var.ami_id
  instance_type = "t2.medium"
  key_name = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  user_data = <<-EOT
#!/bin/bash
hostnamectl set-hostname ${each.key}
echo "127.0.0.1 ${each.key}" >> /etc/hosts

# SSH設定を変更
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

# root の公開鍵設定
mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
echo "${tls_private_key.workstation_key.public_key_openssh}" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chown root:root /root/.ssh/authorized_keys
EOT

  tags = {
    Name = each.key
  }
}

# Workstation用の設定
locals {
  hosts_file_content = join("\n", [
    for key, instance in aws_instance.example :
    "${instance.private_ip} ${key}"
  ])
}

resource "aws_instance" "workstation" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  vpc_security_group_ids = [var.security_group_id]

  user_data = <<-EOT
#!/bin/bash
hostnamectl set-hostname workstation
echo "127.0.0.1 workstation" >> /etc/hosts

echo "${local.hosts_file_content}" >> /etc/hosts

# WorkstationのSSH鍵を設定
mkdir -p /root/.ssh
echo "${tls_private_key.workstation_key.private_key_pem}" > /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
chown root:root /root/.ssh/id_rsa
EOT

  tags = {
    Name = "workstation"
  }
}

# Workstationの秘密鍵をローカルに保存
output "workstation_private_key" {
  value     = tls_private_key.workstation_key.private_key_pem
  sensitive = true
}

# Workstationの公開鍵を出力
output "workstation_public_key" {
  value = tls_private_key.workstation_key.public_key_openssh
}
