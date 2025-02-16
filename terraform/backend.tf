terraform {
  backend "s3" {
   bucket = "sctp-ce8-tfstate"
   key    = "yyf.tfstate"
   region = "ap-southeast-1"
  }
}
