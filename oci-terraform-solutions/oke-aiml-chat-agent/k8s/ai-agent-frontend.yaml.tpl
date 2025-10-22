apiVersion: apps/v1
kind: Deployment
metadata:
  name: ai-agent-frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ai-agent-frontend
  template:
    metadata:
      labels:
        app: ai-agent-frontend
    spec:
      containers:
        - name: streamlit-frontend
          image: ${docker_image}
          imagePullPolicy: Always
          ports:
            - containerPort: 8501
          env:
            - name: CHATBOT_API_URL
              value: "${chatbot_api_url}"
          resources:
            limits:
              cpu: "1"
              memory: "1Gi"
            requests:
              cpu: "0.5"
              memory: "512Mi" 