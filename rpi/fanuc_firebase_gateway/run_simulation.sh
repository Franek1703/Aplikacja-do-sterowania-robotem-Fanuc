#!/bin/bash
# Quick start script for simulation mode

echo "=========================================="
echo "FANUC Firebase Gateway - Simulation Mode"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Creating from example..."
    if [ -f env.example ]; then
        cp env.example .env
        echo "✓ Created .env file. Please edit it with your Firebase credentials."
        echo ""
        echo "Required settings:"
        echo "  - FIREBASE_SERVICE_ACCOUNT: Path to your serviceAccountKey.json"
        echo "  - FIREBASE_RTDB_URL: Your Firebase Realtime Database URL"
        echo "  - DEVICE_ID: Unique identifier for this gateway"
        echo ""
        exit 1
    else
        echo "❌ env.example not found!"
        exit 1
    fi
fi

# Set simulation mode
export SIMULATION=1

echo "Starting gateway in simulation mode..."
echo "Press Ctrl+C to stop"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Add the parent directory to PYTHONPATH so the package can be imported
export PYTHONPATH="${SCRIPT_DIR}/..:${PYTHONPATH}"

cd "${SCRIPT_DIR}"
python3 -m fanuc_firebase_gateway.main

