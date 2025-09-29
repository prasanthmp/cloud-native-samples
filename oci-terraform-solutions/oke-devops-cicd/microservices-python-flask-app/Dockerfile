# Use Python Base Image
FROM python:3.9

# Set Work Directory
WORKDIR /app

# Copy Files
COPY requirements.txt requirements.txt
COPY app.py app.py

# Install Dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose Port
EXPOSE 5100

# Run Flask App
CMD ["python", "app.py"]