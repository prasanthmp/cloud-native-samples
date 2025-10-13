apiVersion: v1
kind: Service
metadata:
  name: ${service_name}
spec:
  type: ClusterIP
  selector:
    app: ${app_name}
  ports:
  - port: 80
    targetPort: ${docker_image_port}