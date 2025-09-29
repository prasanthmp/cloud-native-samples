apiVersion: v1
kind: Service
metadata:
  name: ${webapp_service_name}
spec:
  type: LoadBalancer
  selector:
    app: ${webapp_name}
  ports:
    - protocol: TCP
      port: 80
      targetPort: ${webapp_port}