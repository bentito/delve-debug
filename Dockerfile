# Use the official golang image as a base image
FROM golang:1.17

# Download and install Delve
RUN go install github.com/go-delve/delve/cmd/dlv@latest

# Copy the known entrypoint.sh into the image and give it execute permission
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the entry point of the container to the known entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

