# Go Web App

This is a simple Go web application that displays the server's hostname and IP address. The app is designed to be lightweight and efficient, making it suitable for cloud-native environments.

## Features

- Displays the server's hostname and IP address.
- Logs server information and errors to the console.
- Dockerized for easy deployment.

## Project Structure

go-webapp/ ├── main.go # Main application file ├── Dockerfile # Docker configuration ├── docker-compose.yml # Docker Compose configuration └── templates/ └── index.html # HTML template for the home page


## Prerequisites

- [Go](https://golang.org/) (v1.18 or later)
- [Docker](https://www.docker.com/) (optional, for containerized deployment)

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/prasanthprasad/cloud-native-samples.git
   cd cloud-native-samples/dockerized-apps/web-app/go-webapp

2. Build the Go application:
   ```sh
   go build -o go-webapp

### Usage
Run Locally
1. Start the application:
   ```sh
   ./go-webapp

2. Open your browser and navigate to:
   ```sh
    http://localhost:8080       

Run with Docker
1. Build the Docker image:
   ```sh
    docker build -t go-webapp .

2. Run the Docker container:
   ```sh
    docker run -p 8080:8080 go-webapp

3. Open your browser and navigate to:
   ```sh
    docker run -p 8080:8080 go-webapp

Run with Docker Compose
1. Start the application using Docker Compose:
   ```sh
    docker-compose up

2. Open your browser and navigate to:
   ```sh
    http://localhost:8080

### Logging
Logs are printed to the console for simplicity.

### License
This project is licensed under the MIT License. See the LICENSE file for details.

### Author
Developed by Prasanth Prasad. 
