terraform {

        required_providers {
                aws = {
                        source = "hashicorp/aws"
                        version = "~> 4.0"
                }
        }
}

provider "aws" {
  region = var.aws_region
}

# Create a Shared VPC for Both Clusters
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "k3s_demo_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Environment = "Calico Demo"
    Name        = "Calico Demo igw"
  }
}



module "kubernetes_clusters" {
  source = "./calico-k3s-aws"
  
  # Convert clusters to a map for for_each
  for_each = { for cluster in var.clusters : cluster.cluster_name => cluster }

  # Shared attributes
  vpc_id                   = aws_vpc.main_vpc.id  # Pass the VPC ID
  vpc_cidr_block           = var.vpc_cidr_block           # Pass VPC CIDR block
  igw_id                   = aws_internet_gateway.k3s_demo_igw.id  # Pass IGW ID
  
  cluster_name             = each.value.cluster_name
  idx                      = each.value.idx 
  cluster_domain           = each.value.cluster_domain
  image_id                 = each.value.image_id
  region                   = each.value.region
  profile                  = each.value.profile
  availability_zone_names    = each.value.availability_zone_names
  pod_cidr                 = each.value.pod_cidr
  service_cidr             = each.value.service_cidr
  worker_count             = each.value.worker_count
  cp_instance_type         = each.value.cp_instance_type
  worker_instance_type     = each.value.worker_instance_type
  worker_public_ip         = each.value.worker_public_ip
  key_name                 = each.value.key_name
  k3s_version              = each.value.k3s_version
  k3s_features             = each.value.k3s_features
  files_path               = each.value.files_path

  depends_on = [
    aws_vpc.main_vpc,
    aws_internet_gateway.k3s_demo_igw
  ]

}

 output "kubernetes_clusters" {
   value = module.kubernetes_clusters
 }
