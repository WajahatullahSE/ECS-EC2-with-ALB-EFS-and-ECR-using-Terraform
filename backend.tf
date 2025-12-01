terraform {
  backend "s3" {
    bucket         = "wu-terraform"   
    key            = "terraform/terraform.tfstate" 
    region         = "us-west-2"
    encrypt        = true
  }
}