# Use the official Rust image to build the application
FROM rust:1.69 as builder

# Set the working directory inside the container
WORKDIR /app

# Copy Cargo.toml and Cargo.lock to fetch dependencies
COPY Cargo.toml Cargo.lock ./

# Create a dummy source file to cache dependencies
RUN echo 'fn main() {}' > src/main.rs
RUN cargo build --release

# Copy the rest of the source code
COPY . .

# Build the Rust application
RUN cargo build --release

# Use a smaller image to run the application
FROM debian:bullseye-slim

# Copy the compiled binary from the build stage
COPY --from=builder /app/target/release/RustWebApp /usr/local/bin/RustWebApp

# Expose the port the app runs on
EXPOSE 8080

# Run the application
CMD ["RustWebApp"]
