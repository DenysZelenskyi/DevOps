variable "bucket_name" {
  type = string
}

variable "table_name" {
  type    = string
  default = "terraform-locks"
}

variable "environment" {
  type    = string
  default = "lesson-5"
}