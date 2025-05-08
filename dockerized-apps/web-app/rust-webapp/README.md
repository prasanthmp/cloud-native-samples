

# Rust Web App

This is a simple web application built with Rust and the Actix-web framework. The app displays the server's hostname and IP address and is designed to run in a Docker container.

## Features

- Displays the server's hostname and IP address.
- Built with Rust and Actix-web for high performance.
- Dockerized for easy deployment.

## Project Structure
rust-webapp/ ├── src/ │ └── main.rs # Main application file ├── Dockerfile # Docker configuration ├── Cargo.toml # Rust dependencies and project metadata └── templates/ # (Optional) Directory for additional templates


## Prerequisites

- [Rust](https://www.rust-lang.org/) (v1.65 or later)
- [Docker](https://www.docker.com/) (optional, for containerized deployment)

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/prasanthprasad/cloud-native-samples.git
   cd cloud-native-samples/dockerized-apps/web-app/rust-webapp

2. Build the Rust application:
   ```sh
   cargo build --release

## Usage
Run Locally

1. Start the application:
   ```sh
   cargo run

2. Open your browser and navigate to:
   ```sh
    http://localhost:8080


Run with Docker
1. Build the Docker image:
    ```sh
    docker build -t rust-webapp .

2. Run the Docker container:
    ```sh
    docker run -p 8080:8080 rust-webapp

3. Open your browser and navigate to:
    ```sh
    http://localhost:8080

## Logging
Logs are printed to the console for simplicity.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Author
Developed by Prasanth Prasad.