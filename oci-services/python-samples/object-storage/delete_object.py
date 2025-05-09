import oci

def delete_object(config_file="~/.oci/config", profile="DEFAULT"):
    # Load the OCI config
    config = oci.config.from_file(config_file, profile)

    # Initialize Object Storage client
    object_storage_client = oci.object_storage.ObjectStorageClient(config)

    # Get the namespace (required)
    namespace = object_storage_client.get_namespace().data

    # Specify your bucket and object name
    bucket_name = "my-sample-bucket"         # Replace with your bucket
    object_name = "testfile.txt"              # Replace with the object (file) you want to delete

    # Delete the object
    object_storage_client.delete_object(
        namespace_name=namespace,
        bucket_name=bucket_name,
        object_name=object_name
    )

    print(f"Deleted object '{object_name}' from bucket '{bucket_name}'.")

if __name__ == "__main__":
    delete_object()
