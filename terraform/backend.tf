terraform {
  backend "s3" {
    bucket         = "log-platform-tf-state" # Change to your bucket name
    key            = "eks/log-analytics.tfstate"
    region         = "us-west-2"
    dynamodb_table = "log-platform-tf-locks"
    encrypt        = true
  }
}
