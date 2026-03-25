# OKE Image IDs Utility

A small helper script to list Oracle Cloud Infrastructure (OCI) OKE node image "sources" returned by the OCI CLI `ce node-pool-options get --node-pool-option-id all` command. The script groups available node image sources by CPU family (x86, arm, gpu), extracts the embedded Kubernetes version from the source name, and prints a concise summary including Kubernetes version, image OCID, region, and source name.

This is useful when you need to find the latest OKE-compatible image OCIDs for building node pools or validating node images across regions.

## Location

`oci-utilities/get-oke-image-ids/oke-images.py`

## Prerequisites

- Python 3.7+ installed and `python3` in PATH.
- OCI CLI installed and configured (`oci` command must be available and authenticated). See: https://docs.oracle.com/en-us/iaas/Content/SDKDocs/cliinstall.htm
- The authenticated OCI CLI user must have permission to call `oci ce node-pool-options get` (typically read access to Container Engine resources).

## Installation

No external Python libraries are required beyond the Python standard library. Ensure the OCI CLI is installed and available in your PATH.

If you need the OCI CLI, install it and configure credentials:

```bash
# install OCI CLI (example using script installer)
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# configure
oci setup config
```

## Usage

Run the script with Python:

```bash
python3 oci-utilities/get-oke-image-ids/oke-images.py
```

Options:

- `--cpu {x86,arm,gpu}` : Filter output to a specific CPU family.
- `--display all` : Show all discovered image sources instead of the latest per CPU family.

Examples:

```bash
# show latest entries for each CPU family (default)
python3 oci-utilities/get-oke-image-ids/oke-images.py

# show only ARM images
python3 oci-utilities/get-oke-image-ids/oke-images.py --cpu arm

# show all discovered images
python3 oci-utilities/get-oke-image-ids/oke-images.py --display all
```

## Output format

The script prints a human-readable list grouped by CPU family. Each entry contains:

- `K8s:` the Kubernetes version extracted from the `source-name` (e.g. `OKE-1.23.12` ⇒ `1.23.12`).
- `Region:` the region code parsed from the image OCID.
- `Image ID:` the full image OCID (to use in Terraform/OCI API calls).
- `Source:` the original `source-name` string returned by OCI.

Sample output (truncated):

```
Displaying latest images...

===== Image FAMILY: X86 =====
K8s: 1.26.1 | Region: iad
Image ID: ocid1.image.oc1.iad.xxxxx
Source:   OKE-1.26.1-Oracle-Generated-Image-aarch64

===== Image FAMILY: ARM =====
K8s: 1.26.1 | Region: iad
Image ID: ocid1.image.oc1.iad.yyyyy
Source:   OKE-1.26.1-Oracle-Generated-Image-aarch64
```

## Notes & suggestions

- The script uses a very small heuristic to detect CPU family from the `source-name`. It checks for `aarch64` (ARM), `gpu` (GPU) and otherwise treats sources as `x86`.
- Kubernetes version extraction expects `OKE-x.y.z` somewhere in the `source-name`. If the pattern is not present, the version defaults to `0.0.0` and will sort last.
- The region is parsed from the OCID parts and may not always match an expected region code if the OCID format differs.

## License

This repository follows the license in the project root. See `LICENSE` for details.
