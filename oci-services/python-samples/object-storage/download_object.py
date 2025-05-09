import oci

# Load config
config = oci.config.from_file()

# Initialize Object Storage client
object_storage_client = oci.object_storage.ObjectStorageClient(config)

# Get namespace
namespace = object_storage_client.get_namespace().data

# Define parameters
bucket_name = "data-bucket"
object_name = "testfile.txt"  # The file name in OCI
local_file_path = "./testfile-downloaded.txt"  # Change to your local path

# Get object and download to local file
with open(local_file_path, "wb") as f:
    get_obj = object_storage_client.get_object(namespace, bucket_name, object_name)
    for chunk in get_obj.data.raw.stream(1024 * 1024, decode_content=False):
        f.write(chunk)

print(f"Downloaded '{object_name}' to '{local_file_path}'")
