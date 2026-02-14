# This file should be renamed to backend.tf.off before the first deployment
# After S3 bucket is created, rename it back to backend.tf and run terraform init -migrate-state

terraform {
  backend "s3" {
    bucket         = "denys-terraform-state-uo79t5ob"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
