variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "student_name" {
  type    = string
  default = "denys"
}

variable "environment" {
  type    = string
  default = "lesson-5"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "dynamodb_table_name" {
  type    = string
  default = "terraform-locks"
}