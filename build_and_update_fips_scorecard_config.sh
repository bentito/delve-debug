#!/bin/bash

# Path to your config.yaml file
CONFIG_FILE="../fips-scorecard/bundle/tests/scorecard/config.yaml"

# Base image name
IMAGE_NAME="quay.io/btofel/scorecard-delve-debug"

# Extract the current version number from config.yaml using awk
current_version=$(awk -F ':' '/image: quay.io\/btofel\/scorecard-delve-debug:v/ {print $3}' "$CONFIG_FILE" | sed 's/v//')
echo "Current version: v$current_version"

# Increment the version
new_version=$((current_version + 1))
echo "New version: v$new_version"

# Build and push the new image version
podman build --platform linux/amd64 -t "${IMAGE_NAME}:v$new_version" . && podman push "${IMAGE_NAME}:v$new_version"
echo "Image built and pushed: ${IMAGE_NAME}:v$new_version"

# Update the config.yaml file with the new version using macOS compatible sed
sed -i '' "s_${IMAGE_NAME}:v${current_version}_${IMAGE_NAME}:v${new_version}_g" "$CONFIG_FILE"
echo "Updated config.yaml with the new version: v$new_version"
