#!/bin/bash

# Define namespace and names
NAMESPACE="openshift-file-integrity"
OPERATOR_GROUP_NAME="file-integrity-operator"
SUBSCRIPTION_NAME="file-integrity-operator"
CATALOG_SOURCE="redhat-operators"

# Create a temporary directory for YAML files
TMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TMP_DIR"

# Namespace YAML
cat <<EOF > "$TMP_DIR/namespace.yaml"
apiVersion: v1
kind: Namespace
metadata:
  labels:
    openshift.io/cluster-monitoring: "true"
  name: $NAMESPACE
EOF

# OperatorGroup YAML
cat <<EOF > "$TMP_DIR/operatorgroup.yaml"
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: $OPERATOR_GROUP_NAME
  namespace: $NAMESPACE
spec:
  targetNamespaces:
  - $NAMESPACE
EOF

# Subscription YAML
cat <<EOF > "$TMP_DIR/subscription.yaml"
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: $SUBSCRIPTION_NAME
  namespace: $NAMESPACE
spec:
  channel: "v1"
  installPlanApproval: Automatic
  name: $SUBSCRIPTION_NAME
  source: $CATALOG_SOURCE
  sourceNamespace: openshift-marketplace
EOF

# Apply Namespace
echo "Creating namespace for File Integrity Operator..."
kubectl apply -f "$TMP_DIR/namespace.yaml"

# Apply OperatorGroup
echo "Creating OperatorGroup for File Integrity Operator..."
kubectl apply -f "$TMP_DIR/operatorgroup.yaml"

# Apply Subscription
echo "Creating Subscription for File Integrity Operator..."
kubectl apply -f "$TMP_DIR/subscription.yaml"

# Function to update CSV
update_csv() {
    local CSV_NAME=$1
    local retries=5
    for attempt in $(seq 1 $retries); do
        echo "Attempt $attempt of $retries to update CSV"

        # Fetch the latest version of the CSV
        kubectl get csv $CSV_NAME -n $NAMESPACE -o yaml > file-integrity-csv.yaml


        # Remove existing nodeSelector
        sed -i '' '/nodeSelector:/,+1d' file-integrity-csv.yaml

        # Try to apply the modified CSV
        if kubectl apply -f file-integrity-csv.yaml; then
            echo "CSV updated successfully."
            return 0
        else
            echo "Failed to update CSV. Retrying..."
            sleep 5
        fi
    done

    echo "Failed to update CSV after $retries attempts."
    return 1
}

# Wait for the CSV to be available
echo "Waiting for CSV to become available..."
while true; do
  CSV_NAME=$(kubectl get csv -n $NAMESPACE -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
  if [ ! -z "$CSV_NAME" ]; then
    echo "Retrieved CSV: $CSV_NAME"
    break
  else
    echo "Waiting for CSV to become available..."
    sleep 10
  fi
done

# Call the function to update the CSV
update_csv $CSV_NAME

# Define a variable to hold the FIO pod name
FIO_POD_NAME=""

# Loop to wait for the FIO pod to be created
echo "Waiting for File Integrity Operator pod to be created..."
while [ -z "$FIO_POD_NAME" ]; do
  FIO_POD_NAME=$(kubectl get pods -n $NAMESPACE -l 'name=file-integrity-operator' -o jsonpath="{.items[0].metadata.name}" 2>/dev/null)
  if [ -z "$FIO_POD_NAME" ]; then
    echo "Waiting for the File Integrity Operator pod to become available..."
    sleep 5
  else
    echo "File Integrity Operator pod found: $FIO_POD_NAME"
  fi
done

# Create a ConfigMap with NAMESPACE and FIO_POD_NAME assuming scorecard tests will be run in default namespace
kubectl create configmap scorecard-config --from-literal=scorecard_config.yaml="NAMESPACE=openshift-file-integrity
FIO_POD_NAME=file-integrity-operator-6db6b98bbb-xcn96" -n default


# Check Operator Deployment
echo "Checking File Integrity Operator Deployment Status..."
kubectl get deploy -n $NAMESPACE

# Cleanup
echo "Cleaning up temporary files..."
rm -f file-integrity-csv.yaml

echo "Script execution complete. CSV modified and local files cleaned up."

