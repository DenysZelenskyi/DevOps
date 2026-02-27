terraform {
  backend "s3" {
    bucket         = "denys-terraform-state-0urmgag5"
    key            = "lesson-7/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
