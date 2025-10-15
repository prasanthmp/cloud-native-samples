#!/usr/bin/env bash
echo "Running cloud-init script"
bash /etc/oke/oke-install.sh \
  --apiserver-endpoint ${apiserver_endpoint_private} \
  --kubelet-ca-cert ${kubelet_ca_cert}
echo "Completed cloud-init script"
