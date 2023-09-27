#!/bin/bash
set -e

# Define the image name, tag, and other variables
IMAGE_NAME="delve-debugger"
TAG="latest"
REGISTRY="quay.io/btofel"
GO_APP_IMAGE="golang:latest"
LISTEN_PORT="2345"

# Generate the entrypoint.sh script
cat <<EOL > entrypoint.sh
#!/bin/sh

# Use default port $LISTEN_PORT if not set
LISTEN_PORT=\${LISTEN_PORT:-$LISTEN_PORT}

exec dlv --headless --listen=:\$LISTEN_PORT --api-version=2
EOL

chmod +x entrypoint.sh

# Build the image
podman build -t ${IMAGE_NAME}:${TAG} .

# Tag the image for the registry
podman tag ${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:${TAG}

# Push the image to the registry
podman push ${REGISTRY}/${IMAGE_NAME}:${TAG}

echo "Delve image has been built and pushed as ${REGISTRY}/${IMAGE_NAME}:${TAG}"

# Create the Kubernetes Pod manifest
cat <<EOL > go-app-with-delve.yaml
apiVersion: v1
kind: Pod
metadata:
  name: go-app-with-delve
spec:
  containers:
    - name: go-app
      image: ${GO_APP_IMAGE}
    - name: delve
      image: ${REGISTRY}/${IMAGE_NAME}:${TAG}
      env:
        - name: LISTEN_PORT
          value: "${LISTEN_PORT}"
      securityContext:
        privileged: true
      ports:
        - containerPort: ${LISTEN_PORT}
EOL

echo "Kubernetes Pod manifest has been generated as go-app-with-delve.yaml"

# Create the Delve debug script
cat <<EOL > delve-debug.sh
#!/bin/bash
set -e

# Define variables
NAMESPACE="default"
POD_NAME="go-app-with-delve"
LISTEN_PORT="${LISTEN_PORT}"

# Start port-forwarding
kubectl port-forward --namespace=\$NAMESPACE \$POD_NAME \$LISTEN_PORT:\$LISTEN_PORT &

# Allow some time for port-forwarding to start
sleep 2

# Connect local Delve to the remote Delve instance
dlv connect localhost:\$LISTEN_PORT
EOL

chmod +x delve-debug.sh

echo "Delve debug script has been generated as delve-debug.sh"

