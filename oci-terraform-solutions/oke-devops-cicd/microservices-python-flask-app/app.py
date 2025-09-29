from flask import Flask
import socket

app = Flask(__name__)

@app.route('/')
def home():
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    return f"<h1>Server Info</h1><p>Hostname: {hostname}</p><p>IP Address: {ip_address}</p><p>Image version: v1.18</p>"

if __name__ == '__main__':
    # Bind to 0.0.0.0 so host can access the app
    app.run(host='0.0.0.0', port=5100, debug=True)

