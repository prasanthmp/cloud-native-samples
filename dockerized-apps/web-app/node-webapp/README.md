# Node.js Web App

This is a simple Node.js web application that displays the server's name and IP address. The app is built using the Express framework and uses EJS as the templating engine.

## Features

- Displays the server's hostname and IP address.
- Logs server information and errors to a file (`logs/app.log`).
- Dockerized for easy deployment.

## Project Structure

node-webapp/ ├── app.js # Main application file ├── Dockerfile # Docker configuration ├── package.json # Node.js dependencies and scripts ├── views/ │ └── index.ejs # EJS template for the home page └── logs/ └── app.log # Log file (created at runtime)


## Prerequisites

- [Node.js](https://nodejs.org/) (v18 or later)
- [Docker](https://www.docker.com/) (optional, for containerized deployment)

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/prasanthprasad/cloud-native-samples.git

2. Install dependencies:
    ```sh
    npm install

## Usage
Run Locally
1. Start the application:
    ```sh
    npm start

2. Open your browser and navigate to:
    ```sh
    http://localhost:3000

Run with Docker
1. Build the Docker image:
    ```sh
    docker build -t node-webapp .

2. Run the Docker container:
    ```sh
    docker run -p 3000:3000 node-webapp

3. Open your browser and navigate to:
    ```sh
    http://localhost:3000

## Logging
Logs are saved in the logs/app.log file.
Each log entry includes a timestamp and a message.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Author
Developed by Prasanth Prasad.