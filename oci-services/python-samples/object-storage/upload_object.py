import oci

config = oci.config.from_file()
object_storage_client = oci.object_storage.ObjectStorageClient(config)

namespace = object_storage_client.get_namespace().data
bucket_name = "my-sample-bucket"

file_name = "testfile.txt"

with open(file_name, "rb") as f:
    object_storage_client.put_object(
        namespace_name=namespace,
        bucket_name=bucket_name,
        object_name=file_name,
        put_object_body=f
    )

print(f"File {file_name} uploaded to bucket {bucket_name}.")