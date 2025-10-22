FROM python:3.10-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8501

# Default API path (can be overridden)
ENV CHATBOT_API_URL=http://127.0.0.1:8000/chat

CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
