import oci

config = oci.config.from_file()
compute_client = oci.core.ComputeClient(config)

compartment_id = config["compartment_id"]
instances = compute_client.list_instances(compartment_id).data

for instance in instances:
    print(f"{instance.display_name}: {instance.lifecycle_state}")
