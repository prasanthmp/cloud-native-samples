apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${app_name}
  labels:
    app: ${app_name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${app_name}
  template:
    metadata:
      labels:
        app: ${app_name}
    spec:
      containers:
      - name: ${app_name}
        image: ${docker_image}
        ports:
        - containerPort: ${docker_image_port} # internal port
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi

