#!/bin/bash

# Script to download TensorFlow Lite MoveNet models for pose detection
# Required for web and desktop deployments

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  MoveNet Model Downloader${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# URLs
LIGHTNING_URL="https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/lightning/tflite/float16/4.tflite"
THUNDER_URL="https://storage.googleapis.com/tfhub-lite-models/google/lite-model/movenet/singlepose/thunder/tflite/float16/4.tflite"

# File names
LIGHTNING_FILE="movenet_lightning.tflite"
THUNDER_FILE="movenet_thunder.tflite"

# Check if curl or wget is available
if command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl -L -o"
elif command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget -O"
else
    echo -e "${RED}Error: Neither curl nor wget is installed.${NC}"
    echo "Please install curl or wget and try again."
    exit 1
fi

# Download Lightning model
echo -e "${YELLOW}Downloading MoveNet Lightning model...${NC}"
echo "Source: $LIGHTNING_URL"
echo "Target: $LIGHTNING_FILE"

if [ -f "$LIGHTNING_FILE" ]; then
    echo -e "${YELLOW}Warning: $LIGHTNING_FILE already exists.${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping Lightning model download."
    else
        rm "$LIGHTNING_FILE"
        $DOWNLOAD_CMD "$LIGHTNING_FILE" "$LIGHTNING_URL"
    fi
else
    $DOWNLOAD_CMD "$LIGHTNING_FILE" "$LIGHTNING_URL"
fi

echo ""

# Download Thunder model
echo -e "${YELLOW}Downloading MoveNet Thunder model...${NC}"
echo "Source: $THUNDER_URL"
echo "Target: $THUNDER_FILE"

if [ -f "$THUNDER_FILE" ]; then
    echo -e "${YELLOW}Warning: $THUNDER_FILE already exists.${NC}"
    read -p "Overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping Thunder model download."
    else
        rm "$THUNDER_FILE"
        $DOWNLOAD_CMD "$THUNDER_FILE" "$THUNDER_URL"
    fi
else
    $DOWNLOAD_CMD "$THUNDER_FILE" "$THUNDER_URL"
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Download Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Verify downloads
if [ -f "$LIGHTNING_FILE" ]; then
    LIGHTNING_SIZE=$(ls -lh "$LIGHTNING_FILE" | awk '{print $5}')
    echo -e "✅ Lightning model: ${GREEN}$LIGHTNING_SIZE${NC}"
else
    echo -e "❌ Lightning model: ${RED}NOT FOUND${NC}"
fi

if [ -f "$THUNDER_FILE" ]; then
    THUNDER_SIZE=$(ls -lh "$THUNDER_FILE" | awk '{print $5}')
    echo -e "✅ Thunder model: ${GREEN}$THUNDER_SIZE${NC}"
else
    echo -e "❌ Thunder model: ${RED}NOT FOUND${NC}"
fi

echo ""
echo -e "${GREEN}Models are ready for use!${NC}"
echo ""
echo "Next steps:"
echo "1. Ensure models are listed in pubspec.yaml:"
echo "   assets:"
echo "     - assets/models/movenet_lightning.tflite"
echo "     - assets/models/movenet_thunder.tflite"
echo ""
echo "2. Build your app:"
echo "   flutter build web --release"
echo "   flutter build windows --release"
echo "   flutter build macos --release"
echo ""
