#!/bin/bash

set -e

echo "Building Anki Headless Docker Image..."

# Default versions
ANKI_VERSION=${ANKI_VERSION:-25.07.5}
ANKICONNECT_VERSION=${ANKICONNECT_VERSION:-23.10.29.0}
IMAGE_TAG=${IMAGE_TAG:-anki-headless:latest}

echo "Using Anki version: $ANKI_VERSION"
echo "Using AnkiConnect version: $ANKICONNECT_VERSION"
echo "Building image: $IMAGE_TAG"

# Build the Docker image
docker build \
    --build-arg ANKI_VERSION="$ANKI_VERSION" \
    --build-arg ANKICONNECT_VERSION="$ANKICONNECT_VERSION" \
    -t "$IMAGE_TAG" \
    .

echo "Build completed successfully!"
echo "You can now run: docker-compose up -d"