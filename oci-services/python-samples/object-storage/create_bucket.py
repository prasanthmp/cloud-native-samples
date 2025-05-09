import oci

def create_bucket(config_file="~/.oci/config", profile="DEFAULT"):
    # Load the OCI config
    config = oci.config.from_file(config_file, profile)

    # Initialize Object Storage client
    object_storage_client = oci.object_storage.ObjectStorageClient(config)

    # Get namespace
    namespace = object_storage_client.get_namespace().data

    # Define the bucket details
    compartment_id = config["compartment_id"]  # Set in config file
    bucket_name = "my-sample-bucket"  # Change as needed

    create_bucket_details = oci.object_storage.models.CreateBucketDetails(
        name=bucket_name,
        compartment_id=compartment_id,
        public_access_type="NoPublicAccess",  # Other options: ObjectRead, ObjectReadWithoutList
        storage_tier="Standard"  # Options: Standard, Archive
    )

    # Create the bucket
    response = object_storage_client.create_bucket(
        namespace_name=namespace,
        create_bucket_details=create_bucket_details
    )

    print(f"Bucket '{response.data.name}' created successfully in namespace '{namespace}'.")

if __name__ == "__main__":
    create_bucket()
