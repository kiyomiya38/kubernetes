variable "aws_region" {
  default = "ap-northeast-1"
}

variable "ami_id" {
  default = "ami-0ac6b9b2908f3e20d" # 必要に応じて変更
}

variable "key_name" {
  default = "k8s-key" # AWSに登録済みのSSHキー
}

variable "security_group_id" {
  default = "sg-06402ee46c42f8e96" # 適用するセキュリティグループID
}
