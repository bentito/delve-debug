# Delve Debugger in Kubernetes

This project facilitates the debugging of Go applications running in Kubernetes using Delve. It includes scripts and configurations to set up a Delve debugger in a Kubernetes cluster.

## Components
- **Dockerfile:** Defines the Delve container image.
- **entrypoint.sh:** Serves as the entrypoint for the Delve container, starting Delve in headless mode.
- **build_delve_image.sh:** Builds the Delve container image, tags it, optionally pushes it to a registry, and generates the Kubernetes Pod manifest and a debug script.
- **delve-debug.sh:** A generated script that sets up port-forwarding and connects the local Delve client to the remote Delve server in the Kubernetes cluster.

## Prerequisites
- A Kubernetes Cluster
- `kubectl` installed and configured to interact with your cluster
- `podman` or `docker` to build the image

## Steps to Use

### Build the Delve Image
Run the `build_delve_image.sh` script. It will build the Delve image, generate the Kubernetes Pod manifest (`go-app-with-delve.yaml`), and create the `delve-debug.sh` script.
```sh
./build_delve_image.sh
```

### Deploy the Kubernetes Pod
Deploy the generated Pod manifest to your cluster. The manifest includes both the Go application and the Delve debugger.
```sh
kubectl apply -f go-app-with-delve.yaml
```

### Debug with Delve
Run the generated `delve-debug.sh` script to set up port-forwarding and connect your local Delve client to the remote Delve server within the Kubernetes cluster.
```sh
./delve-debug.sh
```

## Security Considerations
- **Privileged Containers:** The Delve container is running with a privileged security context. This configuration can expose the cluster to security risks. It’s crucial to review the security settings, follow the principle of least privilege, and apply role-based access controls (RBAC) and Pod Security Policies (PSP) as needed.
- **Network Policies:** Ensure that Kubernetes Network Policies are configured to control the communication between Pods, allowing connections between the local machine and the Delve container within the cluster.

## Customization & Troubleshooting
- Review and modify the scripts and configurations to suit your specific needs and environment.
- Check the logs and describe the resources using `kubectl logs <pod-name> -c <container-name>` and `kubectl describe pod <pod-name>` if any step fails to get more details about the errors or issues.

## Contribution & Support
Feel free to contribute to the project by creating issues or pull requests. For support or questions, contact [your contact info or support channel].

