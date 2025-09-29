apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${webapp_name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${webapp_name}
  template:
    metadata:
      labels:
        app: ${webapp_name}
      annotations:
        rollout/restartedAt: ${time_stamp}
    spec:
      imagePullSecrets:
      - name: ocirsecret
      containers:
      - name: ${webapp_name}
        image: ${app_container_image_id}
        imagePullPolicy: Always 
        ports:
        - containerPort: ${webapp_port}
