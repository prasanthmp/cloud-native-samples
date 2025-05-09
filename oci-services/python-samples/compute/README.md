# Create Instance Script

This Python script demonstrates how to create a compute instance in Oracle Cloud Infrastructure (OCI) using the OCI Python SDK. The script launches an instance with a specified shape, image, and configuration.

## Prerequisites

- Python 3.8 or later
- Oracle Cloud Infrastructure (OCI) SDK for Python
- OCI credentials configured in `~/.oci/config`
- An existing Virtual Cloud Network (VCN) and subnet in OCI
- An SSH public key for instance access

## Script Details

### Features

- Launches a compute instance in a specified compartment.
- Configures the instance with a specific shape, memory, and OCPUs.
- Associates the instance with a specified subnet and assigns a public IP.
- Uses an Oracle Linux 8 x86 image by default.

### Configuration

The script uses the following parameters:

- **Instance Shape**: `VM.Standard.E4.Flex` (default)
- **OCPUs**: 1
- **Memory**: 16 GB
- **Image ID**: Oracle Linux 8 x86 image ID (update based on your region)
- **VCN ID**: Replace with your VCN OCID
- **Subnet ID**: Replace with your subnet OCID
- **SSH Key**: Path to your SSH public key (`~/.ssh/ssh-key.pub` by default)

## Project Structure

create_instance.py # Script to create a compute instance in OCI


## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/prasanthprasad/cloud-native-samples.git
   cd cloud-native-samples/oci-services/python-samples/compute

2. Install the required dependencies:
   ```sh
    pip install oci

## Usage
1. Ensure your OCI credentials are configured in ~/.oci/config. The file should look like this:
   ```sh
    [DEFAULT]
    user=ocid1.user.oc1..exampleuniqueID
    fingerprint=20:3b:97:13:55:1c:example
    key_file=/path/to/your/private_api_key.pem
    tenancy=ocid1.tenancy.oc1..exampleuniqueID
    region=us-ashburn-1
    compartment_id=ocid1.compartment.oc1..exampleuniqueID

2. Update the script with your VCN ID, Subnet ID, and Image ID.

3. Run the script:
   ```sh
    python create_instance.py

4. The script will output the OCID of the launched instance:
   ```sh
   Instance launched. OCID: ocid1.instance.oc1..exampleuniqueID

## Notes
- Ensure the specified compartment, VCN, and subnet exist in your OCI tenancy.  
- Update the image_id in the script to match the desired image for your region.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Author
Developed by Prasanth Prasad