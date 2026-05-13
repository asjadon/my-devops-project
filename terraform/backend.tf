terraform {
  backend "s3" {
    bucket         = "my-tf-state-ankit-2024"
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
