provider "aws" {
  region = "eu-west-3"
}


variable vpc_cidr_block {}
variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}



module "myapp-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  # VPC attributes configuration here
    
    # name and cidr block for the VPC
    name = "myapp-vpc"
    cidr = var.vpc_cidr_block

    # AZs and subnets configuration
    azs             = ["us-east-3a", "us-east-3b", "us-east-3c"]
    private_subnets = var.private_subnet_cidr_blocks
    public_subnets  = var.public_subnet_cidr_blocks

    # Enable/disable various features
    enable_nat_gateway = true
    single_nat_gateway = true
    enable_dns_hostnames = true

    tags = {
      Terraform   = "true"
      Environment = "dev"
    }

    # Subnet tags for EKS
    public_subnet_tags = {
      "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
      "kubernetes.io/role/elb" = "1"
    }
    private_subnet_tags = {
      "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
      "kubernetes.io/role/internal-elb" = "1"
    }

}