#!/bin/bash

set -e

echo "Starting Anki headless server..."

# Function to handle shutdown gracefully
cleanup() {
    echo "Shutting down Anki..."
    if [ ! -z "$ANKI_PID" ]; then
        kill -TERM "$ANKI_PID" 2>/dev/null || true
        wait "$ANKI_PID" 2>/dev/null || true
    fi
    if [ ! -z "$XVFB_PID" ]; then
        kill -TERM "$XVFB_PID" 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT

# Start virtual display (required for Anki even in headless mode)
echo "Starting virtual display..."
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!

# Give Xvfb time to start
sleep 2

# Set display environment variable
export DISPLAY=:99

# Ensure Anki directories exist
mkdir -p "${ANKI_DATA_DIR}/User 1/collection.media"
mkdir -p "${ANKI_DATA_DIR}/User 1/addons21/2055492159"

# Initialize Anki profile if it doesn't exist
if [ ! -f "${ANKI_DATA_DIR}/User 1/collection.anki2" ]; then
    echo "Initializing Anki profile..."
    # Create empty collection database
    anki --profile "User 1" --no-gui --create-profile &
    INIT_PID=$!
    sleep 5
    kill -TERM "$INIT_PID" 2>/dev/null || true
    wait "$INIT_PID" 2>/dev/null || true
fi

# Ensure AnkiConnect addon is properly configured
if [ ! -f "${ANKI_DATA_DIR}/User 1/addons21/2055492159/config.json" ]; then
    echo "Creating AnkiConnect configuration..."
    cat > "${ANKI_DATA_DIR}/User 1/addons21/2055492159/config.json" << EOF
{
    "apiKey": null,
    "apiLogPath": null,
    "webBindAddress": "0.0.0.0",
    "webBindPort": ${ANKI_PORT:-8765},
    "webCorsOrigin": "${ANKI_CORS_ORIGINS:-*}",
    "webCorsOriginList": ["${ANKI_CORS_ORIGINS:-*}"]
}
EOF
fi

# Create meta.json for the addon if it doesn't exist
if [ ! -f "${ANKI_DATA_DIR}/User 1/addons21/2055492159/meta.json" ]; then
    echo "Creating AnkiConnect metadata..."
    cat > "${ANKI_DATA_DIR}/User 1/addons21/2055492159/meta.json" << EOF
{
    "name": "AnkiConnect",
    "mod": $(date +%s),
    "disabled": false
}
EOF
fi

echo "Starting Anki with AnkiConnect..."

# Start Anki in the background
anki --profile "User 1" --no-gui --disable-web-security &
ANKI_PID=$!

# Wait for AnkiConnect to be ready
echo "Waiting for AnkiConnect to be ready..."
MAX_ATTEMPTS=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -s -f "http://localhost:${ANKI_PORT:-8765}" > /dev/null 2>&1; then
        echo "AnkiConnect is ready on port ${ANKI_PORT:-8765}"
        break
    fi
    
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: AnkiConnect not ready yet..."
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo "ERROR: AnkiConnect failed to start after $MAX_ATTEMPTS attempts"
    exit 1
fi

echo "Anki headless server is running successfully!"

# Test AnkiConnect API
echo "Testing AnkiConnect API..."
RESPONSE=$(curl -s -X POST "http://localhost:${ANKI_PORT:-8765}" \
    -H "Content-Type: application/json" \
    -d '{"action": "version", "version": 6}' || echo "")

if echo "$RESPONSE" | grep -q '"result"'; then
    echo "AnkiConnect API is working correctly"
    echo "Response: $RESPONSE"
else
    echo "WARNING: AnkiConnect API test failed"
    echo "Response: $RESPONSE"
fi

# Keep the container running
wait $ANKI_PID