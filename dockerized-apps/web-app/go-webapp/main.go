package main

import (
	"fmt"
	"net"
	"net/http"
	"os"
)

// getLocalIP gets the local IP address of the server
func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "Unavailable"
	}

	for _, addr := range addrs {
		// Check if it's an IPv4 address and not a loopback address
		if ipnet, ok := addr.(*net.IPNet); ok && ipnet.IP.IsGlobalUnicast() {
			return ipnet.IP.String()
		}
	}
	return "Unavailable"
}

// handler function to respond with server name and IP
func handler(w http.ResponseWriter, r *http.Request) {
	serverName, err := os.Hostname()
	if err != nil {
		serverName = "Unavailable"
	}

	serverIP := getLocalIP()

	html := fmt.Sprintf(`<html>
		<head><title>Go Web App</title></head>
		<body>
		<center>
			<h1>Welcome to the Go Web App!</h1>
			<img src='https://www.golang.org/doc/gopher/frontpage.png' alt='Gopher' width='200' height='200'/>                 
			<h2>Server Information</h2>
			<p>This is a simple web application built with Go.</p>
			<p>It is designed to run in a Docker container.</p>
			<h4>Server Name: %s</h4>
			<h4>IP Address: %s</h4>
		</center>
		</body>
		</html>`, serverName, serverIP)

	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(html))	
}

func main() {
	http.HandleFunc("/", handler)
	port := "8080"
	fmt.Println("Starting Go Web App on port", port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		fmt.Println("Error starting server:", err)
	}
}
