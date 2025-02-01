                                                                                                 
aws_region         = "us-east-1"
aws_profile        = "default"
credential_file    = "~/.aws/credentials"

vpc_name           = "Multi-Cluster VPC"
vpc_cidr_block     = "172.16.0.0/16"

clusters = [
  {
    cluster_name            = "cluster-a"
    idx                     = 1
    cluster_domain          = "cluster-a.local"
    image_id                = "ami-04b4f1a9cf54c11d0"
    region                  = "us-east-1"
    profile                 = "default"
    availability_zone_names = ["us-east-1a", "us-east-1b", "us-east-1c"]
    pod_cidr                = "10.42.0.0/16"
    service_cidr            = "10.43.0.0/16"
    worker_count            = 1
    cp_instance_type        = "t3.medium"
    worker_instance_type    = "t3.small"
    worker_public_ip        = true
    key_name                = "cluster-a.pem"
    k3s_version             = "1.29"
    k3s_features            = "traefik,local-storage,metrics-server"
    files_path              = "files/"
  },
  {
    cluster_name            = "cluster-b"
    idx                     = 2
    cluster_domain          = "cluster-b.local"
    image_id                = "ami-04b4f1a9cf54c11d0"
    region                  = "us-east-1"
    profile                 = "default"
    availability_zone_names = ["us-east-1a", "us-east-1b", "us-east-1c"]

    pod_cidr                = "10.52.0.0/16"
    service_cidr            = "10.53.0.0/16"
    worker_count            = 1
    cp_instance_type        = "t3.medium"
    worker_instance_type    = "t3.small"
    worker_public_ip        = true
    key_name                = "cluster-b.pem"
    k3s_version             = "1.29"
    k3s_features            = "traefik,local-storage,metrics-server"
    files_path              = "files/"
 }
]
                                                                
