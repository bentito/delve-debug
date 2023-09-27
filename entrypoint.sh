#!/bin/sh

# Use default port 2345 if not set
LISTEN_PORT=${LISTEN_PORT:-2345}

exec dlv --headless --listen=:$LISTEN_PORT --api-version=2

