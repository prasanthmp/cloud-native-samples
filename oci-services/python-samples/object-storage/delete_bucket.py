import oci

def delete_bucket(config_file="~/.oci/config", profile="DEFAULT"):
    # Load OCI configuration
    config = oci.config.from_file(config_file, profile)

    # Initialize Object Storage client
    object_storage_client = oci.object_storage.ObjectStorageClient(config)

    # Get namespace
    namespace = object_storage_client.get_namespace().data

    # Define bucket name
    bucket_name = "my-sample-bucket"  # Replace with your bucket name

    # Ensure bucket is empty before deletion
    print(f"Checking if bucket '{bucket_name}' is empty...")
    list_objects_response = object_storage_client.list_objects(namespace, bucket_name)

    if list_objects_response.data.objects:
        print(f"Bucket '{bucket_name}' is not empty. Please delete all objects before deleting the bucket.")
        return

    # Delete the bucket
    object_storage_client.delete_bucket(
        namespace_name=namespace,
        bucket_name=bucket_name
    )

    print(f"Bucket '{bucket_name}' deleted successfully.")

if __name__ == "__main__":
    delete_bucket()
