#!/bin/bash
set -euo pipefail

if [ $# -lt 3 ]; then
  echo "Usage: $0 <compartment_ocid> <oke_cluster_ocid> <tag_value>"
  exit 1
fi

COMPARTMENT_OCID=$1
OKE_CLUSTER_OCID=$2
TAG_VALUE=$3
EXTERNAL_IP=$4

# Get matching LBs by checking display-name for cluster ID
LB_IDS=$(oci lb load-balancer list \
  --compartment-id "$COMPARTMENT_OCID" \
  --query "data[?\"defined-tags\".\"Oracle-Tags\".\"CreatedBy\" == '$OKE_CLUSTER_OCID'].[id]" \
  --raw-output | jq -r 'flatten | .[]'
)

if [ -z "$LB_IDS" ]; then
  echo "❌ No load balancers found for cluster $OKE_CLUSTER_OCID"
  exit 0
fi

i=1

for LB_ID in $LB_IDS; do

    # Get the current display name of the load balancer
    LB_IP=$(oci lb load-balancer get \
    --load-balancer-id $LB_ID \
    --query "data.\"ip-addresses\"[0].\"ip-address\"" \
    --raw-output)

    # Check if IP matches EXTERNAL_IP
    if [[ "$LB_IP" != "$EXTERNAL_IP" ]]; then
        continue
    fi    

    # Wait until LB is ACTIVE with timeout
    MAX_WAIT=60   # total wait time in seconds
    INTERVAL=10   # check interval in seconds
    ELAPSED=0    

    while true; do
        STATE=$(oci lb load-balancer get \
        --load-balancer-id "$LB_ID" \
        --query "data.\"lifecycle-state\"" \
        --raw-output)

        if [ "$STATE" == "ACTIVE" ]; then
        break
        fi

        if [ $ELAPSED -ge $MAX_WAIT ]; then
        echo "❌ Timeout: '$LB_ID' did not become ACTIVE within $MAX_WAIT seconds. Skipping..."
        continue 2  # skip to next LB
        fi

        echo "⏳ '$LB_ID' not ACTIVE. Waiting $INTERVAL seconds..."
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
    done

  NEW_TAG="OKE-$TAG_VALUE-LB-$i"

    # Update the LB with the new tag
  oci lb load-balancer update \
    --load-balancer-id "$LB_ID" \
    --freeform-tags '{"LBID":"'"$NEW_TAG"'"}' \
    --force  

  # Increment counter
  i=$((i+1))

  echo "✅ Updated Load Balancer '$LB_ID' with new tag: $NEW_TAG"  
done
