terraform {
  backend "s3" {
    bucket         = "myapp-terraform-state-dev-5623c6e1"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
