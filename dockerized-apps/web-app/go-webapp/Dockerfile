# Use official Golang image to build the application
FROM golang:1.18-alpine as builder

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod tidy

# Copy the rest of the source code
COPY . .

# Build the Go application
RUN go build -o /go-web-app

# Start from a smaller image to run the application
FROM alpine:latest

# Copy the Go binary from the build stage
COPY --from=builder /go-web-app /go-web-app

# Expose the port the app runs on
EXPOSE 8080

# Command to run the application
CMD ["/go-web-app"]
