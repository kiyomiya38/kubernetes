variable "aws_region" {
  default = "ap-northeast-3"
}

variable "ami_id" {
  default = "ami-0a0bcba223270ed99" # 必要に応じて変更
}

variable "key_name" {
  default = "test-key" # AWSに登録済みのSSHキー
}

variable "security_group_id" {
  default = "sg-08b2d9099b3ba1340" # 適用するセキュリティグループID
}
