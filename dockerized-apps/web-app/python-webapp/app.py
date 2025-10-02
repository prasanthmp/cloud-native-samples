from flask import Flask, render_template
import socket
import logging

# Initialize the Flask app
app = Flask(__name__)

# Set up logging
logging.basicConfig(filename='app.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

@app.route('/')
def index():
    try:
        # Get server name and IP address
        server_name = socket.gethostname()
        server_ip = socket.gethostbyname(server_name)

        # Log the information
        app.logger.info(f"Server Name: {server_name}")
        app.logger.info(f"Server IP: {server_ip}")
    except Exception as e:
        server_name = "Unavailable"
        server_ip = "Unavailable"
        app.logger.error(f"Error fetching server info: {e}")

    return render_template('index.html', server_name=server_name, server_ip=server_ip)

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
