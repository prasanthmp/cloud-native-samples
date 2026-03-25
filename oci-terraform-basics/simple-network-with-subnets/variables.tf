
# Variable for the OCI Compartment ID
variable "compartment_id" {
  description = "The OCID of the compartment."
  type        = string
}

# Variable for the OCI Region
variable "region" {
  description = "The OCI region where the resources will be created."
  type        = string
  default     = "us-phoenix-1"  # Default region, modify if necessary
}

# Variable for the Availability Domain (AD) to be used
variable "availability_domain" {
  description = "The Availability Domain in which to launch resources."
  type        = string
  default     = "Uocm:PHX-AD-1"  # Replace with your AD if needed
}

variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "The OCID of the user"
  type        = string
}

variable "private_key_path" {
  description = "The path to the private key file"
  type        = string
}

variable "fingerprint" {
  description = "The fingerprint of the private key"
  type        = string
}

# # Variable for VCN CIDR block
# variable "vcn_cidr_block" {
#   description = "The CIDR block for the VCN."
#   type        = string
#   default     = "10.0.0.0/16"
# }

# # Variable for Public Subnet CIDR block
# variable "public_subnet_cidr_block" {
#   description = "The CIDR block for the public subnet."
#   type        = string
#   default     = "10.0.0.0/24"
# }

# # Variable for the NGINX Docker image
# variable "nginx_image" {
#   description = "The container image to use for the NGINX container."
#   type        = string
#   default     = "nginx:latest"
# }

# # Variable for the container instance display name
# variable "container_instance_name" {
#   description = "The display name for the container instance."
#   type        = string
#   default     = "nginx-container-instance"
# }

# # Variable for the public IP name
# variable "public_ip_name" {
#   description = "The display name for the public IP."
#   type        = string
#   default     = "nginx-public-ip"
# }

# # Variable to allow you to modify the allocated size of the public IP
# variable "public_ip_lifetime" {
#   description = "The lifetime of the public IP. Options are 'RESERVED' or 'DYNAMIC'."
#   type        = string
#   default     = "RESERVED"
# }

# # Variable for security list ingress rules
# variable "allowed_ip_range" {
#   description = "The IP range allowed to access the container instance (for SSH or HTTP)."
#   type        = string
#   default     = "0.0.0.0/0"  # Open to all IPs, adjust for security in production
# }

# # Variable to define whether you want to create an internet gateway
# variable "create_igw" {
#   description = "Whether or not to create an internet gateway."
#   type        = bool
#   default     = true
# }
