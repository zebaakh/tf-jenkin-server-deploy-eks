terraform {
  backend "s3" {
    bucket = "eks-tf-jenkin-poc"
    region = "us-east-1"
    key    = "jenkins-server/terraform.tfstate"
  }
}
