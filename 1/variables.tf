
variable "domain_name" {
    description = "The domain name you want to deploy"
    type    = string
    default = "www.example.com"
}

#defaults to London for the region
variable "aws_region" {
    description = "The AWS region you want to deploy"
    type    = string
    default = "eu-west-2"
}

#your access key and secret keys to do the wqork in AWS
variable "aws_access_key"{
    default = ""
}
variable aws_secret_key{
    default = ""
}

variable "client_name"{
    description = "Set the client all this should be for to allow for easier billing"
    type    = string
    default = "KPMG"

}