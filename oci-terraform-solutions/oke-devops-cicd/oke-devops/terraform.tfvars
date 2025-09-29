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

# Public SSH client CIDR to allow access to the Kubernetes cluster
my_ipaddress = "0.0.0.0/0" # Open to all - Not recommended for production

# Image ID for K8S node
# This changes by each region
#https://docs.oracle.com/en-us/iaas/Content/ContEng/Reference/contengimagesshapes.htm
# oci ce node-pool-options get --node-pool-option-id all
# region: PHX
#node_image_id = "ocid1.image.oc1.phx.aaaaaaaaeqp6t7uqwgceqkqsark7rleaj5qqb4agur35vp6zpd67audcelta" # ARM
#node_image_id = "ocid1.image.oc1.phx.aaaaaaaaukgdut6qddwqf5kcami23kucfjnevkjkm5bx5dw24cpr4uy4zlva" # AMD
# region: IAD
#node_image_id = "ocid1.image.oc1.iad.aaaaaaaasnbi4aalhxsv36r32eejjomlzrhsfbbhrcbzwptrbzhlspc2kqqa" # AMD
# region: Chicago
node_image_id = "ocid1.image.oc1.us-chicago-1.aaaaaaaa27lqjmb7nqayfiiwvkw5xrszkbfbxj3l33wp7ek7iajv3hptb7fq" # AMD

# All OCI services gateway for the region
all_oci_services_gw = "all-ord-services-in-oracle-services-network"
# You can find the region key from the below link
# https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm
# Example: all-ord-services-in-oracle-services-network # Chicago region
# Example: all-iad-services-in-oracle-services-network # Ashburn region

# OCID of your secret in OCI Vault
# Create a secret in OCI Vault to store the auth token for OCIR
oci_auth_token_vault = "ocid1.vaultsecret.oc1.us-chicago-1.xxxxx" # OCI Vault OCID of Auth token from OCI console, used for authentication
oci_user_namespace = "xxxxx" # Replace with your OCI username namespace
notification_email = "xxx.xxxx@xxx.com" # Email address for CICD notifications
webapp_image = "webapp-repo/$OCI_BUILD_RUN_ID" # Image in OCIR

# OCIR (Oracle Cloud Infrastructure Registry) configuration
ocir = {
  host = "ocir.us-chicago-1.oci.oraclecloud.com" # The host for the Oracle Cloud Infrastructure Container Registry
  username = "xxx.xxx@xxx.com" # The username for the OCIR repository
  email = "xxx.xxx@xx.com"
}

#######################
# End of MUST CHANGE PARAMETERS

# Log Group Name for the application logs
log_group_name = "oke-devops-cicd-log-group"

# Web application configuration
webapp_name = "my-webapp"
webapp_service_name = "my-webapp-service"
webapp_port = 5100

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

# This section defines the DevOps project and build pipeline configuration
devops = {
  build_runner_image = "OL7_X86_64_STANDARD_10"
  code_repository_name = "microservices-python-flask-app" # Name of the private repository
  project_name = "oke-devops-cicd" # Name of the DevOps project
}


# OVERVIEW

# This script is designed to automate the setup of a CICD pipeline using Oracle Cloud Infrastructure (OCI) DevOps, OKE, and a Flask application using Terraform.
# It includes the creation of a VCN, subnets, an OKE cluster, and a DevOps project for CI/CD.
# It also sets up notifications for build and deployment status, and provides instructions for accessing the application once deployed.
# This script is intended for educational purposes and should be modified according to your specific requirements.

# PREREQUISITES - TO RUN THE SCRIPT

# Before running the script, ensure you have the following prerequisites:
# 1. An Oracle Cloud Infrastructure account with the necessary permissions to create and manage resources.
# 2. A valid OCI CLI configuration with the correct region, tenancy OCID, compartment OCID, user OCID, and private key path.
# 3. Terraform installed on your local machine or CI/CD environment.
# 4. Create a secret in OCI Vault to store the auth token for OCIR and update the oci_auth_token_vault variable in .tfvars file.
# 5. Kubectl installed (brew install kubectl)

# HOW TO RUN THE SCRIPT

# Configuring and executing the Terraform script for OCI infrastructure setup and application deployment  
# Step 1: Create OCI infrastructure with all resources

# 1. Replace the values in terraform.tfvars and create new file terraform.local.tfvars with your actual configuration, including region, tenancy OCID, compartment OCID, user OCID, private key path, public SSH client CIDR, notification email, and other resource configurations.
# 2. Run ./build.sh to initialize and apply the Terraform configuration.
# 3. You will receive an email subscription request for notifications. Approve the subscription to start receiving notifications.
# 4. Monitor the Terraform output for the progress of resource creation, build, and deployment

# Step 2: Push the web app code to the private repository to trigger the build and deployment pipeline
# 1. Navigate to the microservices-python-flask-app directory
# 2. Clone the private repository created in the DevOps project. Use the repository URL from the Terraform output.
#    git clone <repository_url>
# 3. Navigate to the cloned repository directory
#    cd microservices-python-flask-app
# 4. Make any necessary changes to the application code (optional)
# 5. Commit and push the changes to the main branch to trigger the build and deployment pipeline
#    ./gitpush.sh
# 6. Monitor the build and deployment process in the OCI DevOps console
# 7. Once the deployment is successful, you will receive a notification email
# 8. You can also monitor the build and deployment status in the OCI DevOps console

# Step 3: Access the deployed Flask application
# 1. Use the Load Balancer IP address from the Terraform output to access the Flask application in your web browser
# 2. You should see the Flask application running and displaying the server information

# Step 4: Access the OKE cluster using kubectl
# Run kubectl commands to interact with the OKE cluster from your local machine
# kubeconfig will be downloaded to your local machine in the location specified in the Terraform output
# Example command to get the nodes in the OKE cluster:
# kubectl get nodes

# HOW TO TRIGGER A NEW BUILD AND DEPLOYMENT

# To trigger a new build and deployment, make changes to the application code in the microservices-python-flask-app directory, commit the changes, and push them to the main branch of the private repository.
# This will automatically trigger the build and deployment pipeline in the OCI DevOps project.

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
# Please refer to the kubectl documentation https://kubernetes.io/docs/tasks/tools/install-kubectl/
# 1. Install kubectl on your local machine if not already installed.

