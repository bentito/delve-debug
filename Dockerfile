FROM golang:1.21

# Install Delve
RUN go install github.com/go-delve/delve/cmd/dlv@latest

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Make the script executable
RUN chmod +x /entrypoint.sh

# Set the entrypoint script as the entrypoint of the container
ENTRYPOINT ["/entrypoint.sh"]
