# This file is used to define the variables for the Terraform configuration.
# Make sure to keep this file secure as it contains sensitive information such as passwords.

# MUST CHANGE PARAMETERS
#######################

# <TODO> Change your OCI CLI configuration to use the correct region, tenancy, compartment, user OCID, and private key path.
# CLI configuration is essential for Terraform to authenticate and manage resources in your Oracle Cloud Infrastructure account.
# CLI config file is usually located at ~/.oci/config
# Sample CLI config file:
# [DEFAULT]
# user=<user_ocid> 
# fingerprint=<fingerprint>
# key_file=<path_to_private_key>
# tenancy=<tenancy_ocid>
# region=<region>
# Note: Make sure to replace the above values with your actual OCI CLI configuration.
# Ensure that the OCI CLI is installed and configured correctly on your machine.
# Make sure to set up the OCI CLI correctly before running Terraform.

# Region where the resources will be created
# Ensure that the region is correct and supported by your Oracle Cloud Infrastructure account
# You can find the list of available regions in the OCI console or documentation
# Note: The region should match the one where your tenancy and compartment are located
region = "xxxx" 

# Tenancy OCID of your Oracle Cloud Infrastructure account
# Ensure that the tenancy OCID is correct and that you have permissions to create resources in this tenancy
# You can find the tenancy OCID in the OCI console under Identity & Access Management > Tenancy Details
tenancy_ocid = "ocid1.tenancy.xxxx"

# Compartment OCID where resources will be created
# Ensure that the compartment OCID is correct and that you have permissions to create resources in this compartment
# You can find the compartment OCID in the OCI console under Identity & Access Management > Compartments
compartment_ocid = "ocid1.compartment.xxxx"

# User OCID of the user who has permissions to manage resources in the tenancy
# Make sure this user has the necessary permissions to create and manage resources in the specified compartment
user_ocid = "ocid1.user.xxxx"

# Fingerprint of the private key used for authentication
# This fingerprint is generated when you create the API key in the OCI console
fingerprint = "xxxx"

# Ensure the private key path is correct and accessible
# Note: The private key should be in PEM format and have the correct permissions (readable only by the owner)
private_key_path = "xxxx/private.pem"

# IP Address of the machine that runs terraform. This could be your local machine or a CI/CD server
# This IP address is used to restrict access to the Kubernetes API endpoint and Grafana/Prometheus dashboards
# Make sure to use CIDR notation (e.g., x.x.x.x/32 for a single IP address)
# Can access K8S endpoint from this
# Can SSH to node
# Can access grafana and prometheus dashboards
my_ipaddress = "xxxxx/32"

# Image ID for K8S node
# This changes by each region
# https://docs.oracle.com/en-us/iaas/Content/ContEng/Reference/contengimagesshapes.htm
# oci ce node-pool-options get --node-pool-option-id all
node_image_id = "ocid1.image.xxxx"
# Example image ID for AMD shape in Chicago: "ocid1.image.oc1.us-chicago-1.aaaaaaaa27lqjmb7nqayfiiwvkw5xrszkbfbxj3l33wp7ek7iajv3hptb7fq" # Chicago

# All OCI services gateway for the region
all_oci_services_gw = "all-REGION-KEY-services-in-oracle-services-network"
# You can find the region key from the below link
# https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm
# Example: all-ord-services-in-oracle-services-network # Chicago region
# Example: all-iad-services-in-oracle-services-network # Ashburn region

#######################
# End of MUST CHANGE PARAMETERS

# Additional Configuration
# Cloud Network Configuration
# This section defines the cloud network configuration including VCN, public and private subnets
cloud_network = {
  vcn_cidr_block     = "10.0.0.0/16"
  node_subnet_cidr = "10.0.10.0/24"
  k8sApiEndpoint_cidr = "10.0.0.0/28"
  loadBalancer_cidr = "10.0.20.0/24"
}

# Kubernetes Configuration
# This section defines the Kubernetes configuration for the OKE cluster
kubernetes = {
  version = "v1.33.1" # Specify the Kubernetes version for the OKE cluster
  cluster_name = "oke-mnode-cluster" # Name of the OKE cluster
  node_pool_name = "node-pool" # Name of the node pool
  node_pool_shape = "VM.Standard.E4.Flex" # Shape for the node pool VM.Standard.E4.Flex
  number_of_nodes = 1 # Number of nodes in the OKE cluster
  type = "ENHANCED_CLUSTER" 
}

# Kubernetes Node Shape Configuration
node_shape = {
  ocpus = 1 # OCPUs for node
  memory = 8 # Memory in GB for node
}

# PREREQUISITES - TO RUN THE SCRIPT

# Before running the script, ensure you have the following prerequisites:
# 1. An Oracle Cloud Infrastructure account with the necessary permissions to create and manage resources.
# 2. A valid OCI CLI configuration with the correct region, tenancy OCID, compartment OCID, user OCID, and private key path.
# 3. Terraform installed on your local machine or CI/CD environment.
# 4. Access to the OCI console to verify the resources created and monitor the build and deployment process.
# 5. Ensure that you have the necessary permissions to create and manage resources in your Oracle Cloud Infrastructure account.
# 6. Kubectl installed (brew install kubectl)
# 7. Helm installed (brew install helm)

# HOW TO RUN THE SCRIPT

# Configuring and executing the Terraform script for OCI infrastructure setup and application deployment  
# Step 1: Create OCI infrastructure with all resources
# 1. Create a new file terraform.local.tfvars with the values in terraform.tfvars with your actual configuration, including region, tenancy OCID, compartment OCID, user OCID, private key path, public SSH client CIDR, notification email, and other resource configurations.
# 2. Run `./build.sh` to initialize and apply the Terraform configuration.
# 3. Once the script completes successfully, you will see Prometheus and Grafana URL

# Step 2: Access Prometheus and Grafana dashboard
# 1. Access Prometheus URL
# 2. Access Grafana URL with default user

# Step 3: Access Kubernetes cluster
# Script will create kubeconfig and will copy to $HOME/.kube/config
# 1. Install kubectl
# brew install kubectl
# 2. Verify kubectl is installed
# kubectl version --client
# 3. Check nodes in the cluster
# kubectl get nodes
# 4. Check all namespaces
# kubectl get namespaces

# ADDITIONAL NOTES:

# Prometheus only work on MANAGED NODES (Not virtual nodes). DaemonSet workloads are not supported on Virtual Nodes
# Find IMAGE ID for VM images corresponds to then selected VM type (Required for managed nodes)
# Check limits on your LB if it shows <PENDING>
# Set KUBECONFIG to the downloaded kubeconfig to connect to the cluster and use kubectl

# ADDITIONAL INFORMATION:

# How to configure OCI CLI
# Please refer to the OCI CLI documentation https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm
# 1. Install OCI CLI on your local machine if not already installed.
# 2. Open a terminal and run the following command to configure OCI CLI:
# oci setup config
# 3. Follow the prompts to enter your tenancy OCID, user OCID, fingerprint, and private key path.
# 4. Make sure to set the correct region for your OCI account.
# 5. Once configured, you can use OCI CLI commands to manage your Oracle Cloud Infrastructure resources.
# 6. You can verify the OCI CLI configuration by running the following command:
# oci iam user get --user-id <your_user_ocid>
# 7. Replace <your_user_ocid> with your actual user OCID.
# 8. This command should return the details of your user if the OCI CLI is configured correctly.
# 9. You can also run other OCI CLI commands to manage your resources, such as creating instances, managing VCNs, and more.
# 10. Make sure to keep your OCI CLI configuration secure and do not share it with anyone.

# How to configure kubectl
# Please refer to the Kubernetes documentation https://kubernetes.io/docs/tasks/tools/install-kubectl/