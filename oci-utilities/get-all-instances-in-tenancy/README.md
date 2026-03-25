# Get All Instances in Tenancy

This utility lists OCI Compute instances across **all subscribed regions** and **all active compartments** in a tenancy.

It reports instances in these lifecycle states:
- `RUNNING` (shown in green)
- `TERMINATED` (shown in red)

## File
- `get-instances.py`

## Prerequisites
- Python 3.8+
- OCI SDK for Python (`oci`)
- Valid OCI CLI/SDK config file at `~/.oci/config`
- Permissions to:
  - read compartments
  - read region subscriptions
  - list compute instances

## Install dependencies
```bash
pip install oci
```

## OCI config
Make sure `~/.oci/config` is configured correctly (for example, using profile `DEFAULT`).

Minimum required keys typically include:
- `user`
- `fingerprint`
- `key_file`
- `tenancy`
- `region`

## Run
From this directory:
```bash
python3 get-instances.py
```

## What it does
1. Loads OCI config from `~/.oci/config`
2. Gets all subscribed regions for the tenancy
3. Gets all active compartments (including root)
4. For each region and compartment, lists instances
5. Prints details for `RUNNING` and `TERMINATED` instances:
   - Region
   - Compartment
   - Instance Name
   - Instance OCID
   - State

## Notes
- Output is printed to terminal only (no CSV/JSON file is generated).
- ANSI color codes are used for state display; some terminals may not render colors.
