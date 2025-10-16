# Image Recognition API using a pre-trained deep learning model

This project is a sample AI/ML microservice for image recognition, designed to be containerized and deployed in cloud-native environments. It demonstrates how to build, package, and run a Python-based image recognition API using modern DevOps and cloud-native practices.

The API leverages the pre-trained ResNet50 deep learning model from TensorFlow/Keras, which is widely used for image classification tasks. TensorFlow provides the backend for model inference, enabling the service to recognize objects in images using state-of-the-art neural network techniques. The model is loaded with ImageNet weights for accurate, out-of-the-box predictions.

## Features
- RESTful API for image recognition using a pre-trained ResNet50 deep learning model
- Powered by TensorFlow/Keras for model inference
- Built with Python (see `app.py`)
- Containerized with Docker
- Easily deployable to Kubernetes or other container orchestration platforms

## Project Structure
- `app.py` — Main application code for the image recognition API
- `requirements.txt` — Python dependencies
- `Dockerfile` — Container build instructions

## Getting Started

### Prerequisites
- Python 3.8+
- Docker

### Install Dependencies
```bash
pip install -r requirements.txt
```


### Run Locally

1. Install dependencies (if not already done):
	```bash
	pip install -r requirements.txt
	```

2. Start the FastAPI server using Uvicorn:
	```bash
	uvicorn app:app --reload --host 0.0.0.0 --port 5000
	```

3. The API will be available at [http://localhost:5000/docs](http://localhost:5000/docs) for interactive Swagger UI and at [http://localhost:5000/redoc](http://localhost:5000/redoc) for ReDoc documentation.

### Build and Run with Docker
```bash
docker build -t image-recognition-api .
docker run -p 5000:5000 image-recognition-api
```


## Models and Libraries Used

- **Model:**
	- [ResNet50](https://keras.io/api/applications/resnet/#resnet50-function): A deep convolutional neural network pre-trained on the ImageNet dataset, used for image classification tasks. The model is loaded with `weights="imagenet"` for out-of-the-box predictions.

- **Libraries:**
	- **FastAPI:** High-performance web framework for building APIs with Python 3.7+.
	- **Uvicorn:** ASGI server for running FastAPI applications.
	- **TensorFlow / Keras:** Used for loading the ResNet50 model and performing image preprocessing and prediction.
	- **Pillow:** Python Imaging Library (PIL) fork, used for image manipulation and processing.
	- **python-multipart:** Enables FastAPI to handle file uploads.

## API Usage
- The API exposes endpoints for image recognition tasks. See `app.py` for details on available routes and request formats.

## Deployment
- This service is designed to be deployed as a container in Kubernetes or other cloud-native platforms.

## License
This project is licensed under the MIT License. See the main repository's `LICENSE` file for details.
