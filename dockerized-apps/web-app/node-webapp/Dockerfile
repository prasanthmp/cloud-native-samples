# Use official Node.js image as the base image
FROM node:18-slim

# Set working directory in the container
WORKDIR /app

# Copy the package.json and package-lock.json (if it exists)
COPY package*.json ./

# Install the app dependencies
RUN npm install

# Copy the rest of the app's files
COPY . .

# Expose the app's port
EXPOSE 3000

# Run the application
CMD ["node", "app.js"]
