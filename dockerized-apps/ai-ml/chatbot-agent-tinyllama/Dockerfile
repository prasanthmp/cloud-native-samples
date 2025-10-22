# Stage 1: Builder
FROM python:3.10-slim AS builder
WORKDIR /app

# Copy dependencies
COPY requirements.txt .
RUN pip install --default-timeout=300 --no-cache-dir -r requirements.txt

# Copy app code
COPY app.py /app

# Expose API port
EXPOSE 8000

# Run FastAPI via Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
