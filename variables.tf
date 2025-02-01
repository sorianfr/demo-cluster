variable "aws_region" {}
variable "aws_profile" {}
variable "credential_file" {}
variable "vpc_name" {}
variable "vpc_cidr_block" {}

variable "clusters" {
  type = list(object({
    cluster_name            = string
    idx                     = number
    cluster_domain          = string
    image_id                = string
    region                  = string
    profile                 = string
    availability_zone_names = list(string)
    pod_cidr                = string
    service_cidr            = string
    worker_count            = number
    cp_instance_type        = string
    worker_instance_type    = string
    worker_public_ip        = bool
    key_name                = string
    k3s_version             = string
    k3s_features            = string
    files_path              = string
  }))
}


