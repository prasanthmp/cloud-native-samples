# Python Web App

This is a simple Python web application built with Flask. The app displays the server's hostname and IP address and logs the information to a file. It is designed to run in a Docker container.

## Features

- Displays the server's hostname and IP address.
- Logs server information and errors to a file (`logs/app.log`).
- Dockerized for easy deployment.

## Project Structure

python-webapp/ ├── app.py # Main application file ├── templates/ │ └── index.html # HTML template for the home page ├── logs/ │ └── app.log # Log file (created at runtime) ├── requirements.txt # Python dependencies └── Dockerfile # Docker configuration


## Prerequisites

- [Python](https://www.python.org/) (v3.8 or later)
- [Flask](https://flask.palletsprojects.com/) (installed via `requirements.txt`)
- [Docker](https://www.docker.com/) (optional, for containerized deployment)

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/prasanthprasad/cloud-native-samples.git
   cd cloud-native-samples/dockerized-apps/web-app/python-webapp

2. Create a virtual environment and activate it:
   ```sh
   python3 -m venv venv
   source venv/bin/activate

3. Install dependencies:
   ```sh   
   pip install -r requirements.txt

## Usage
Run Locally

1. Start the application:
   ```sh
   python app.py

2. Open your browser and navigate to:
   ```sh
        http://127.0.0.1:5000

Run with Docker
1. Build the Docker image:
    ```sh
    docker build -t python-webapp .

2. Run the Docker container:
    ```sh
    docker run -p 5000:5000 python-webapp

3. Open your browser and navigate to:
    ```sh
    http://localhost:5000

## Logging
Logs are saved in the logs/app.log file. 
Each log entry includes a timestamp, log level, and message.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Author
Developed by Prasanth Prasad.