# Delve Debugger in Kubernetes

This project sets up a Delve debugger in a Kubernetes cluster, allowing developers to debug Go applications running within the cluster.

## Components
- **Dockerfile:** Defines the Delve container image.
- **entrypoint.sh:** Serves as the entrypoint for the Delve container, starting Delve in headless mode.
- **build_delve_image.sh:** Builds the Delve container image, tags it, optionally pushes it to a registry, and generates the Kubernetes Pod manifest and a debug script.
- **delve-debug.sh:** A generated script that sets up port-forwarding and connects the local Delve client to the remote Delve server in the Kubernetes cluster.

## Steps to Use
### 1. Build the Delve Image
Run the `build_delve_image.sh` script. This script performs the following tasks:
- Builds the Delve container image using Podman.
- Tags the built image.
- (Optional) Pushes the image to the specified container registry.
- Generates the Kubernetes Pod manifest (`go-app-with-delve.yaml`) for deploying the Go application and Delve containers.
- Generates the `delve-debug.sh` script for connecting to the remote Delve instance.
```sh
./build_delve_image.sh

