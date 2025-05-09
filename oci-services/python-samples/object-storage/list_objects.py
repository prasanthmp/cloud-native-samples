import oci

# Load config (default location ~/.oci/config, default profile)
config = oci.config.from_file()

# Initialize Object Storage client
object_storage_client = oci.object_storage.ObjectStorageClient(config)

# Get the namespace (required)
namespace = object_storage_client.get_namespace().data

# Define your bucket and compartment
bucket_name = "data-bucket"

# List objects in the bucket
list_objects_response = object_storage_client.list_objects(
    namespace_name=namespace,
    bucket_name=bucket_name
)

print("Objects in bucket:", bucket_name)
# Print object names (files)
for obj in list_objects_response.data.objects:
    print(obj.name)
