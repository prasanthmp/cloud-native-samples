import subprocess
import json
import re
from collections import defaultdict
import argparse


def detect_cpu_family(name: str) -> str:
    """Detect CPU type from source-name."""
    name_lower = name.lower()
    if "aarch64" in name_lower:
        return "arm"
    if "gpu" in name_lower:
        return "gpu"
    return "x86"  # default to x86 for Intel/AMD


def extract_k8s_version(name: str) -> str:
    """Extract Kubernetes version from source-name."""
    match = re.search(r"OKE-(\d+\.\d+\.\d+)", name)
    return match.group(1) if match else "0.0.0"


def parse_version(version: str):
    """Convert version string 'x.y.z' to tuple (x, y, z) for sorting."""
    try:
        return tuple(int(x) for x in version.split("."))
    except:
        return (0, 0, 0)


def extract_region(image_id: str) -> str:
    """Extract region code from Image OCID."""
    parts = image_id.split(".")
    if len(parts) >= 4:
        return parts[3]
    return "Unknown"


def run_oci_command():
    """Run OCI CLI and return parsed JSON."""
    cmd = ["oci", "ce", "node-pool-options", "get", "--node-pool-option-id", "all"]
    try:
        output = subprocess.check_output(cmd, text=True)
        return json.loads(output)
    except subprocess.CalledProcessError as e:
        print("Error executing OCI command:", e)
        exit(1)


def main():
    parser = argparse.ArgumentParser(description="OCI Node Pool Options Viewer")
    parser.add_argument(
        "--cpu",
        choices=["x86", "arm", "gpu"],
        help="Filter by CPU type"
    )
    parser.add_argument(
        "--display",
        choices=["all"],
        help="Display all items instead of latest"
    )
    args = parser.parse_args()

    data = run_oci_command()
    images = data.get("data", {}).get("sources", [])

    grouped = defaultdict(list)

    for img in images:
        source_name = img.get("source-name", "")
        image_id = img.get("image-id", "")

        cpu_family = detect_cpu_family(source_name)
        k8s_version = extract_k8s_version(source_name)
        region = extract_region(image_id)

        grouped[cpu_family].append({
            "kubernetes_version": k8s_version,
            "source_name": source_name,
            "image_id": image_id,
            "region": region
        })

    # Sort each CPU family by Kubernetes version descending
    for cpu_family in grouped:
        grouped[cpu_family].sort(
            key=lambda x: parse_version(x["kubernetes_version"]), reverse=True
        )

    # Filter by CPU type if --cpu is supplied
    cpu_families_to_show = [args.cpu] if args.cpu else grouped.keys()

    # Number of items to display per CPU family
    max_display = None if args.display == "all" else 1

    # Display message at the top
    if args.display == "all":
        print("Displaying all images...\n")
    else:
        print("Displaying latest image.\n")

    # Print output
    for cpu_family in cpu_families_to_show:
        items = grouped.get(cpu_family, [])
        if not items:
            continue
        print(f"===== Image FAMILY: {cpu_family.upper()} =====")
        for item in items[:max_display]:
            print(f"K8s: {item['kubernetes_version']} | Region: {item['region']}")
            print(f"Image ID: {item['image_id']}")
            print(f"Source:   {item['source_name']}")
            print("")


if __name__ == "__main__":
    main()
