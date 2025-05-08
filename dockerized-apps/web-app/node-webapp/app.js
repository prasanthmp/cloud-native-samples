const express = require('express');
const os = require('os');
const path = require('path');
const fs = require('fs');

// Initialize Express app
const app = express();
const port = 3000;

// Set up a simple logging function
const logData = (message) => {
  const logMessage = `${new Date().toISOString()} - ${message}\n`;
  fs.appendFileSync('logs/app.log', logMessage);
};

// Set EJS as the view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Route for the home page
app.get('/', (req, res) => {
  try {
    // Get server name and IP address
    const serverName = os.hostname();
    const serverIP = Object.values(os.networkInterfaces())
      .flat()
      .find(iface => iface.family === 'IPv4' && !iface.internal)
      ?.address || 'Unavailable';

    // Log server name and IP
    logData(`Server Name: ${serverName}`);
    logData(`Server IP: ${serverIP}`);

    // Render the template with server info
    res.render('index', { serverName, serverIP });
  } catch (error) {
    logData(`Error: ${error.message}`);
    res.render('index', { serverName: 'Unavailable', serverIP: 'Unavailable' });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Node web app listening at http://localhost:${port}`);
});
