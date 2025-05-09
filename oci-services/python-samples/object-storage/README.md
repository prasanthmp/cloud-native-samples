# Object Storage Python Samples

This folder contains Python sample scripts demonstrating how to interact with Oracle Cloud Infrastructure (OCI) Object Storage service. These examples showcase common operations such as creating buckets, uploading objects, downloading objects, and listing objects in a bucket.

## Prerequisites

- Python 3.8 or later
- Oracle Cloud Infrastructure (OCI) SDK for Python
- OCI credentials configured in `~/.oci/config`

## Project Structure

object-storage/ ├── create_bucket.py # Script to create a new bucket ├── upload_object.py # Script to upload an object to a bucket ├── download_object.py # Script to download an object from a bucket ├── list_objects.py # Script to list objects in a bucket ├── delete_object.py # Script to delete an object from a bucket ├── delete_bucket.py # Script to delete a bucket └── README.md # Documentation for the folder


## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/prasanthprasad/cloud-native-samples.git
   cd cloud-native-samples/oci-services/python-samples/object-storage

2. Install the required dependencies:
   ```sh
    pip install oci

## Usage
1. Configure OCI Credentials  
2. Ensure you have an OCI configuration file at ~/.oci/config. The file should look like this:  
    ```sh
    [DEFAULT]
    user=ocid1.user.oc1..exampleuniqueID
    fingerprint=20:3b:97:13:55:1c:example
    key_file=/path/to/your/private_api_key.pem
    tenancy=ocid1.tenancy.oc1..exampleuniqueID
    region=us-ashburn-1

## Run Examples  
1. Create a Bucket:
    ```sh
    python create_bucket.py

2. Upload an Object:
    ```sh
    python upload_object.py

3. Download an Object:
    ```sh
    python download_object.py

4. List Objects in a Bucket:
    ```sh
    python list_objects.py

5. Delete an Object:
    ```sh
    python delete_object.py

6. Delete a Bucket:
    ```sh
    python delete_bucket.py

## License  
This project is licensed under the MIT License. See the LICENSE file for details.

## Author  
Developed by Prasanth Prasad.