provider "kubernetes" {
  host = data.aws_eks_cluster.myapp-eks.endpoint
  token = data.aws_eks_cluster_auth.myapp-eks.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-eks.certificate_authority.0.data)

  # Optional: Disable SSL verification if needed
  load_config_file       = false
}

data "aws_eks_cluster" "myapp-eks" {
  name = module.eks.cluster_id # Ensure this matches your EKS cluster name
}

data "aws_eks_cluster_auth" "myapp-eks" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.2.0"

  # Cluster configuration
  name    = "myapp-eks-cluster" # Use 'name' instead of 'cluster_name'
  kubernetes_version = "1.27" # Use 'kubernetes_version' instead of 'cluster_version'

  vpc_id  = module.myapp-vpc.vpc_id
  subnet_ids = module.myapp-vpc.private_subnets # use subnet_ids instead of private_subnets

  # Node group configuration
  eks_managed_node_groups = { # Use 'eks_managed_node_groups' instead of 'node_groups'
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t2.micro"] # Use 'instance_types' instead of 'instance_type'

      additional_tags = {
        Name = "eks-node-group"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
