#!/bin/bash
set -e

# Define the image name, tag, and other variables
IMAGE_NAME="delve-debugger"
TAG="latest"
REGISTRY="quay.io/btofel"
TARGET_GO_APP_IMAGE="registry.redhat.io/quay/quay-operator-rhel8@sha256:b0aeb0a047adadf3e25f9a1abd24fa9299ee06c13976470465cb5fd155ff44fb"
LISTEN_PORT="2345"

# Generate the entrypoint.sh script
cat <<EOL > entrypoint.sh
#!/bin/sh
LISTEN_PORT=\${LISTEN_PORT:-$LISTEN_PORT}
TARGET_PID=\$(for prc in /proc/[0-9]*; do [ -f "\$prc/cmdline" ] || continue; cmd=\$(tr '\0' ' ' < "\$prc/cmdline"); case "\$cmd" in *bash*|*sh*|*init*|*pod*) continue ;; *) echo \$prc ;; esac; done | sed 's|/proc/||' | head -n 1)
if [ -z "\$TARGET_PID" ]; then echo "Error: target application process not found."; exit 1; fi
exec dlv --headless --listen=:\$LISTEN_PORT --api-version=2 attach \$TARGET_PID
EOL

chmod +x entrypoint.sh

# Build, tag and push the image
podman build -t ${IMAGE_NAME}:${TAG} .
podman tag ${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:${TAG}
podman push ${REGISTRY}/${IMAGE_NAME}:${TAG}

echo "Delve image has been built and pushed as ${REGISTRY}/${IMAGE_NAME}:${TAG}"

# Create the Kubernetes Pod manifest
cat <<EOL > target-go-app-with-delve.yaml
apiVersion: v1
kind: Pod
metadata:
  name: target-go-app-with-delve
spec:
  shareProcessNamespace: true
  containers:
    - name: target-go-app
      image: ${TARGET_GO_APP_IMAGE}
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

echo "Kubernetes Pod manifest has been generated as target-go-app-with-delve.yaml"

# Create the Delve debug script
cat <<EOL > delve-debug.sh
#!/bin/bash
NAMESPACE=default
POD_NAME=target-go-app-with-delve
LISTEN_PORT=2345
PACKAGE_NAME=boringcrypto
DEBUG=0

if [[ \$1 == "--debug" ]]; then
    DEBUG=1
fi

function debug_output {
    if [[ \$DEBUG -eq 1 ]]; then
        echo "\$1"
    fi
}

debug_output "Checking for existing port-forward on port \$LISTEN_PORT."

if pgrep kubectl > /dev/null; then
    debug_output "A kubectl command is running. Trying to kill existing port-forward on port \$LISTEN_PORT."
    lsof -ti :\$LISTEN_PORT | while read -r pid; do
        kill \$pid
    done
    sleep 2
fi

debug_output "Starting port-forward."

if [[ \$DEBUG -eq 1 ]]; then
    kubectl port-forward --namespace=\$NAMESPACE \$POD_NAME \$LISTEN_PORT:\$LISTEN_PORT &
else
    kubectl port-forward --namespace=\$NAMESPACE \$POD_NAME \$LISTEN_PORT:\$LISTEN_PORT &> /dev/null &
fi

sleep 5

DLV_OUTPUT=\$(expect << EOF
spawn dlv connect localhost:\$LISTEN_PORT
expect "Type 'help' for list of commands."
send "funcs \$PACKAGE_NAME.*\r"
expect "(dlv)"
send "exit\r"
expect eof
EOF
)

if ! echo "\$DLV_OUTPUT" | grep -v '^(dlv)' | grep -q "\${PACKAGE_NAME}"; then
    echo "Failure: \$PACKAGE_NAME package is NOT used."
    debug_output "Raw Output from dlv command with package \$PACKAGE_NAME.:"
    debug_output "\$DLV_OUTPUT"
    kill %1
    exit 1
fi

echo "Success: \$PACKAGE_NAME package is used."
kill %1
exit 0
EOL

chmod +x delve-debug.sh

echo "Delve debug script has been generated as delve-debug.sh"
