variable "environment" {
  type    = string
  default = "lesson-5"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  type    = bool
  default = false
}