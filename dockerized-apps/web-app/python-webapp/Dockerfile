# Use the official Python image as a base image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt (if you create one later) and install dependencies
COPY . .

# Install Flask and any other dependencies
RUN pip install Flask

# Expose port 5000
EXPOSE 5000

# Set environment variable to disable buffering of logs
ENV PYTHONUNBUFFERED 1

# Run the application
CMD ["python", "app.py"]
