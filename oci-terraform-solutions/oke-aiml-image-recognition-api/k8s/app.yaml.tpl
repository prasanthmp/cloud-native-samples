apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-recognition
spec:
  replicas: 2
  selector:
    matchLabels:
      app: image-recognition
  template:
    metadata:
      labels:
        app: image-recognition
    spec:
      containers:
      - name: image-recognition
        image: ${docker_image}
        ports:
        - containerPort: 8080