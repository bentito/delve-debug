# Delve Debugging to find run-time crypto libs for FIPS compliance in Kubernetes

The idea here is to run Delve the Go debugger in two place, as a container aside the target image under test container, and locally so Delve can be scripted to assert the `boringcyrpto` package is loaded at run-time.
We attempt to automate attaching to the correct binary from the Delve container. You should configure some of the environment variables
used in `build_delve_image.sh`, as follows:
`REGISTRY` - where to push the delve debugger image;
`TARGET_GO_APP_IMAGE` - the image under test

## Components
- **Dockerfile:** Defines the Delve container image.
- **build_delve_image.sh:** Builds and pushes the Delve container image to a registry, and generates the Kubernetes Pod manifest and a debug script.
- **delve-debug.sh:** A generated script that sets up port-forwarding and connects the local Delve client to the remote Delve server in the Kubernetes cluster. 
This tool errors if `boringcrypto` package is not found in the binary and succeeds if it is. 

## Prerequisites
- A Kubernetes Cluster
- `kubectl` installed and configured to interact with your cluster
- `podman` or `docker` to build and push the image

## Usage
### 1. Build and Push the Delve Image
Execute the `build_delve_image.sh` script. It will build the Delve image, push it to the specified registry, generate the Kubernetes Pod manifest (`target-go-app-with-delve.yaml`), and create the `delve-debug.sh` script.
```sh
./delve-debug.sh
```
Execute the `build_delve_image.sh` script.
```sh
./delve-debug.sh
```
It takes a few moments for the network connection to the remote Delve, then it should exit with success or failure.

### 2. Deploy the Kubernetes Pod
Deploy the generated Pod manifest to your cluster. The manifest includes the target Go application and the Delve debugger.
```sh
kubectl apply -f target-go-app-with-delve.yaml
```

### 3. Debug with Delve
Run the generated `delve-debug.sh` script to set up port-forwarding and connect your local Delve client to the remote Delve server within the Kubernetes cluster.
```sh
./delve-debug.sh
```

## Security Considerations
- **Privileged Containers:** The Delve container is running with a privileged security context. This configuration can expose the cluster to security risks. It’s crucial to review the security settings, follow the principle of least privilege, and apply role-based access controls (RBAC) and Pod Security Policies (PSP) as needed.
- **Network Policies:** Ensure that Kubernetes Network Policies are configured to control the communication between Pods, allowing connections between the local machine and the Delve container within the cluster.
.

