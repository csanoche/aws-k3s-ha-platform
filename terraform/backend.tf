terraform {
  backend "s3" {
    bucket         = "aws-k3s-ha-platform-tf-bucket-720459752427-ap-southeast-1-an"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    use_lockfile   = true
    encrypt        = true
  }
}