terraform {
  backend "s3" {
    bucket         = "denys-terraform-state-<suffix>" # Update with actual bucket name from output
    key            = "lesson-7/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
