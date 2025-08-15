#!/bin/bash

# Test script for AnkiConnect API
set -e

ANKI_HOST=${ANKI_HOST:-localhost}
ANKI_PORT=${ANKI_PORT:-8765}
BASE_URL="http://${ANKI_HOST}:${ANKI_PORT}"

echo "Testing AnkiConnect API at ${BASE_URL}"

# Function to make API request
api_request() {
    local action="$1"
    local params="$2"
    local version="${3:-6}"
    
    if [ -z "$params" ]; then
        params="{}"
    fi
    
    local data=$(cat <<EOF
{
    "action": "$action",
    "version": $version,
    "params": $params
}
EOF
    )
    
    echo "Testing: $action"
    response=$(curl -s -X POST "$BASE_URL" \
        -H "Content-Type: application/json" \
        -d "$data")
    
    if echo "$response" | grep -q '"error":null'; then
        echo "✅ $action - SUCCESS"
        echo "Response: $response"
    else
        echo "❌ $action - FAILED"
        echo "Response: $response"
        return 1
    fi
    echo ""
}

# Test basic connectivity
echo "🔍 Checking AnkiConnect connectivity..."
if ! curl -s --max-time 5 "$BASE_URL" > /dev/null; then
    echo "❌ Cannot connect to AnkiConnect at $BASE_URL"
    echo "Make sure the container is running: docker-compose ps"
    exit 1
fi

echo "✅ Successfully connected to AnkiConnect"
echo ""

# Test API endpoints
echo "🧪 Running API tests..."

# Test version
api_request "version"

# Test deck names
api_request "deckNames"

# Test model names
api_request "modelNames"

# Test creating a note (optional - only if Default deck exists)
echo "📝 Testing note creation..."
note_params='{
    "note": {
        "deckName": "Default",
        "modelName": "Basic",
        "fields": {
            "Front": "Docker Test Card",
            "Back": "This is a test card created by the API test script"
        },
        "tags": ["docker-test", "api-test"]
    }
}'

if api_request "addNote" "$note_params"; then
    echo "✅ Note creation test passed"
else
    echo "⚠️ Note creation test failed (this might be normal if Default deck doesn't exist)"
fi

echo ""
echo "🎉 API testing completed!"
echo "AnkiConnect is working correctly at $BASE_URL"