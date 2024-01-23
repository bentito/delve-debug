#!/bin/bash

# Define namespace and resource permissions
NAMESPACE="openshift-file-integrity"
RESOURCE="pods"
VERBS="list"

# Create a Role with permissions to list pods
echo "Creating a Role to list pods in the default namespace..."
kubectl create role pod-lister --verb=$VERBS --resource=$RESOURCE --namespace=$NAMESPACE

# Bind this Role to the default service account
echo "Creating a RoleBinding for the default service account to use the pod-lister Role..."
kubectl create rolebinding default-pod-lister --role=pod-lister --serviceaccount=$NAMESPACE:default --namespace=$NAMESPACE

echo "RBAC setup complete."

