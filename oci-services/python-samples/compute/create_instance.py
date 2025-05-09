import oci
import os

# Load config from ~/.oci/config
config = oci.config.from_file()
compartment_id = config["compartment_id"]

# Instance details
# Replace with your desired values
instance_shape = "VM.Standard.E4.Flex"
instance_display_name = "my-x86-instance"
instance_shape_config = oci.core.models.LaunchInstanceShapeConfigDetails(
    ocpus=1,
    memory_in_gbs=16
)
vcn_id = "ocid1.vcn.oc1.us-chicago-1.amaaaaaak6zxdwaaw6xwad3xuumzyspyegk6n7zmet7cvyuksnoybrqreyxa"
subnet_id = "ocid1.subnet.oc1.us-chicago-1.aaaaaaaaxm7w66oliplwrmv657b57msndyoz64su7ow6qrp4kshhceerhidq"

# 1. Get first availability domain
identity_client = oci.identity.IdentityClient(config)
ad = identity_client.list_availability_domains(compartment_id).data[0].name

# 2. Get compatible Oracle Linux 8 x86 image ID
# Find image id based on your region and OS type
# For example, in US-Chicago-1, the image ID for Oracle Linux 8 x86 is:
# ocid1.image.oc1.us-chicago-1.aaaaaaaayx2hcxe6lvwui4l7goo6tssvyrwfz2st5mydvtbfwlipl5wf557q
# https://docs.oracle.com/en-us/iaas/images/oracle-linux-8x/oracle-linux-8-10-2025-04-16-0.htm
image_id = "ocid1.image.oc1.us-chicago-1.aaaaaaaayx2hcxe6lvwui4l7goo6tssvyrwfz2st5mydvtbfwlipl5wf557q"

# 3. Load SSH public key
ssh_key_path = os.path.expanduser("~/.ssh/ssh-key.pub")
if not os.path.exists(ssh_key_path):
    raise Exception("SSH public key not found. Generate one with ssh-keygen.")
with open(ssh_key_path) as f:
    ssh_key = f.read()

# 4. Create instance details
launch_details = oci.core.models.LaunchInstanceDetails(
    compartment_id=compartment_id,
    availability_domain=ad,
    display_name=instance_display_name,
    shape=instance_shape,
    shape_config=instance_shape_config,
    metadata={"ssh_authorized_keys": ssh_key},
    create_vnic_details=oci.core.models.CreateVnicDetails(
        subnet_id=subnet_id,
        assign_public_ip=True,
        display_name="vnic1"
    ),
    source_details=oci.core.models.InstanceSourceViaImageDetails(
        source_type="image",
        image_id=image_id
    )
)

# 5. Launch the instance
print("Launching instance...")
compute_client = oci.core.ComputeClient(config)
response = compute_client.launch_instance(launch_details)
print("Instance launched. OCID:", response.data.id)
