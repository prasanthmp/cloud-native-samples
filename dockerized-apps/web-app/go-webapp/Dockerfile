# Use official Golang image to build the application
FROM golang:1.21-alpine AS builder

# Install security updates
RUN apk update && apk upgrade && apk add --no-cache ca-certificates

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod ./

# Download dependencies
RUN go mod tidy

# Copy the rest of the source code
COPY . .

# Build the Go application with security flags
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o /go-web-app

# Use distroless image for better security
FROM gcr.io/distroless/static-debian12:nonroot

# Copy CA certificates and binary from builder
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go-web-app /go-web-app

# Expose the port the app runs on
EXPOSE 8080

# Command to run the application
CMD ["/go-web-app"]
