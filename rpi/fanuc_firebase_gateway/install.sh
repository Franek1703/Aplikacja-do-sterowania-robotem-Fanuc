#!/bin/bash
# Installation script for FANUC Firebase Gateway

set -e

echo "============================================================"
echo "FANUC Firebase Gateway - Installation"
echo "============================================================"
echo ""

# Check Python version
echo "Checking Python version..."
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "Found Python $python_version"

# Check if we're in a virtual environment
if [ -z "$VIRTUAL_ENV" ]; then
    echo ""
    echo "WARNING: No virtual environment detected!"
    echo "It's recommended to use a virtual environment."
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
fi

echo ""
echo "Step 1: Installing FANUC package..."
cd ../fanuc_package
pip install -e .
echo "✓ FANUC package installed"

echo ""
echo "Step 2: Installing Firebase Gateway dependencies..."
cd ../fanuc_firebase_gateway
pip install -r requirements.txt
echo "✓ Firebase Gateway dependencies installed"

echo ""
echo "============================================================"
echo "Installation Complete!"
echo "============================================================"
echo ""
echo "Next steps:"
echo "1. Copy env.example to .env and configure Firebase credentials"
echo "2. Run: python3 -m main"
echo ""

