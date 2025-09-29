version: 0.1
component: build
timeoutInSeconds: 6000
shell: bash
failImmediatelyOnError: true

env:
  variables:
    IMAGE_TAG: ${ocir_repo}
  vaultVariables:
    AUTH_TOKEN_OCI: ${oci_auth_token}
  exportedVariables:
    - IMAGE_TAG

steps:
  - type: Command
    timeoutInSeconds: 400
    name: "Export variable IMAGE_TAG"
    command: |
      export IMAGE_TAG=${ocir_image_id}
      echo "IMAGE_TAG: $IMAGE_TAG"
      echo "OCI_BUILD_RUN_ID: $OCI_BUILD_RUN_ID"    

  - type: Command
    timeoutInSeconds: 400
    name: "Login to Docker Registry"
    command:
      echo "$AUTH_TOKEN_OCI" | docker login ${ocir_host} -u '${ocir_username}' --password-stdin

  - type: Command
    timeoutInSeconds: 400
    name: "Build Docker Image"
    command:
      docker build -t ${ocir_image_id} .

  - type: Command
    timeoutInSeconds: 400
    name: "Push Docker Image"
    command: |
      docker push ${ocir_image_id}