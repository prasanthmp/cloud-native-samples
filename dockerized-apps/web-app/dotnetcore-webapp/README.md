# .NET Core Web App

This is a simple .NET Core web application that uses Razor Pages. The app is designed to be lightweight and can be easily deployed in a Docker container.

## Features

- Built with .NET Core and Razor Pages.
- Configurable logging to the console.
- Dockerized for easy deployment.

## Project Structure
dotnetcore-webapp/ ├── Program.cs # Main application entry point ├── Pages/ # Razor Pages for the web app ├── wwwroot/ # Static files (CSS, JS, etc.) ├── appsettings.json # Application configuration ├── Dockerfile # Docker configuration └── dotnetcore-webapp.csproj # Project file with dependencies

## Prerequisites

- [.NET SDK](https://dotnet.microsoft.com/) (v6.0 or later)
- [Docker](https://www.docker.com/) (optional, for containerized deployment)

## Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/prasanthprasad/cloud-native-samples.git
   cd cloud-native-samples/dockerized-apps/web-app/dotnetcore-webapp

2. Restore dependencies:
   ```sh
   dotnet restore

## Usage
Run Locally

1. Start the application:
   ```sh
   dotnet run

2. Open your browser and navigate to:
   ```sh
    https://localhost:5001


Run with Docker
1. Build the Docker image:
    ```sh
    docker build -t dotnetcore-webapp .

2. Run the Docker container:
    ```sh
    docker run -p 5001:5001 dotnetcore-webapp

3. Open your browser and navigate to:
    ```sh
    http://localhost:5001

## Logging
Logs are printed to the console for simplicity.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Author
Developed by Prasanth Prasad.