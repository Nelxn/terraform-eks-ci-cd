provider "aws" {
  region     = "eu-west-3"
}


# VPC, Subnet, Internet Gateway, Route Table, Security Group, EC2 Instance
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "${var.env_name}-vpc"
  }
}

resource "aws_subnet" "jenkins_subnet" {
  vpc_id            = aws_vpc.jenkins_vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone

  tags = {
    Name = "${var.env_name}-subnet"
  }
}

resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "${var.env_name}-igw"
  }
}


resource "aws_route_table" "jenkins_route_table" {
  vpc_id = aws_vpc.jenkins_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }

  tags = {
    Name = "${var.env_name}-route-table"
  }
}
resource "aws_route_table_association" "jenkins_route_table_assoc" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_route_table.id
}

resource "aws_security_group" "jenkins" {
  name = "jenkins-sg"
  vpc_id = aws_vpc.jenkins_vpc.id

  # allow inbound SSH traffic only from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks  = [var.my_ip]
  }
  
  # allow inbound traffic on port 8080 from anywhere
  ingress {
    description = "Allow Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }
  
  # allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.env_name}-sg"
  }

}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


# assuming you have already created a key pair and have the public key in the specified path
resource aws_key_pair "ssh-key" {
  key_name   = "server-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Create an EC2 instance
resource "aws_instance" "myapp-ec2" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  availability_zone = var.avail_zone
  
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  
  
  # entry script to install docker or reference a file in local system or this terraform directory
user_data = <<-EOF
  #!/bin/bash
  set -e

  export DEBIAN_FRONTEND=noninteractive

  # Wait for apt locks in case of cloud-init race
  while sudo fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
    echo "Waiting for apt locks to be released..."
    sleep 2
  done

  # Update and upgrade system
  sudo apt-get update -y
  sudo apt-get upgrade -y

  # Install lsb-release and required packages
  sudo apt-get install -y lsb-release apt-transport-https ca-certificates curl gnupg unzip software-properties-common

  # Install Docker
  sudo apt-get install -y docker.io
  sudo systemctl enable --now docker
  sudo usermod -aG docker ubuntu

  # Install AWS CLI v2
  if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -o /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
  fi

  # Install kubectl directly (latest stable)
  curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm kubectl

  # Install Terraform (official repo, no variables)
  sudo apt-get install -y gnupg
  curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update -y
  sudo apt-get install -y terraform

  # Install Java (required for Jenkins)
  sudo apt-get install -y openjdk-17-jre

  # Install Jenkins from official repo (no variables)
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
  sudo apt-get update -y
  sudo apt-get install -y jenkins
  sudo systemctl daemon-reload
  sudo systemctl enable --now jenkins
EOF


  tags = {
    Name = "${var.env_name}-ec2"
  }

}