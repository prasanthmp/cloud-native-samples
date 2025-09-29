apiVersion: v1
kind: Secret
metadata:
  name: ocirsecret
  namespace: default
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: ${dockerconfigjson}
