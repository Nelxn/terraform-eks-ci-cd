variable db_name {}
variable db_username {}
variable db_password {}
variable cluster_name {}

# Subnet group for RDS (only private subnets)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.cluster_name}-rds-subnets"
  subnet_ids = module.myapp-vpc.private_subnets

  tags = {
    Name = "${var.cluster_name}-rds-subnet-group"
  }
}

# Security group allowing EKS worker nodes to access RDS on port 5432
resource "aws_security_group" "rds_sg" {
  name        = "${var.cluster_name}-rds-sg"
  description = "Allow Postgres from EKS worker nodes"
  vpc_id      = module.myapp-vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "Allow Postgres from EKS workers"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-rds-sg"
    Environment = "dev"
    Terraform   = "true"
  }
}

# RDS Instance
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.0"

  identifier        = "myapp-db"
  engine            = "postgres"
  engine_version    = "15.5" # latest free-tier eligible PostgreSQL version
  family            = "postgres15"
  instance_class    = "db.t3.micro" # free-tier eligible
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Attach RDS to correct SG + subnets
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  subnet_ids             = module.myapp-vpc.private_subnets

  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
