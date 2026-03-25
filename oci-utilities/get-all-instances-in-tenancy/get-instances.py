import oci

# ANSI color codes
GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"


def get_all_compartments(identity_client, tenancy_id):
    compartments = [{"id": tenancy_id, "name": "root"}]

    response = oci.pagination.list_call_get_all_results(
        identity_client.list_compartments,
        tenancy_id,
        compartment_id_in_subtree=True,
        access_level="ANY"
    )

    for comp in response.data:
        if comp.lifecycle_state == "ACTIVE":
            compartments.append({"id": comp.id, "name": comp.name})

    return compartments


def get_subscribed_regions(identity_client, tenancy_id):
    regions = []

    response = identity_client.list_region_subscriptions(tenancy_id)

    for region in response.data:
        regions.append(region.region_name)

    return regions


def list_instances(compute_client, compartment_id):

    response = oci.pagination.list_call_get_all_results(
        compute_client.list_instances,
        compartment_id
    )

    instances = []
    for inst in response.data:
        if inst.lifecycle_state in ["RUNNING", "TERMINATED"]:
            instances.append(inst)

    return instances


def main():

    config = oci.config.from_file()
    tenancy_id = config["tenancy"]

    identity_client = oci.identity.IdentityClient(config)

    regions = get_subscribed_regions(identity_client, tenancy_id)
    compartments = get_all_compartments(identity_client, tenancy_id)

    print("\nInstances (RUNNING + TERMINATED) Across Tenancy\n")

    for region in regions:

        print(f"\nScanning Region: {region}")
        print("=" * 60)

        regional_config = config.copy()
        regional_config["region"] = region

        compute_client = oci.core.ComputeClient(regional_config)

        for comp in compartments:

            instances = list_instances(compute_client, comp["id"])

            for inst in instances:

                if inst.lifecycle_state == "RUNNING":
                    state_color = GREEN + "RUNNING" + RESET
                elif inst.lifecycle_state == "TERMINATED":
                    state_color = RED + "TERMINATED" + RESET
                else:
                    state_color = inst.lifecycle_state

                print(f"Region        : {region}")
                print(f"Compartment   : {comp['name']}")
                print(f"Instance Name : {inst.display_name}")
                print(f"Instance OCID : {inst.id}")
                print(f"State         : {state_color}")
                print("-" * 60)


if __name__ == "__main__":
    main()