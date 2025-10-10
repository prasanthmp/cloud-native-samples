apiVersion: v1
kind: Service
metadata:
  name: hello-service
spec:
  type: ClusterIP
  selector:
    app: hello-app
  ports:
  - port: 80
    targetPort: ${docker_image_port}