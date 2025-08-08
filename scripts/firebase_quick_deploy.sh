#!/bin/bash

# Firebase Firestore Index Quick Deploy Script for Linux/macOS
# Tương đương với firebase_index_manager.bat cho Unix systems

set -e

echo "========================================"
echo "Firebase Firestore Index Manager (Unix)"
echo "========================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Firebase CLI
echo "[1/6] Checking Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}ERROR: Firebase CLI not found.${NC}"
    echo "Please install it first: npm install -g firebase-tools"
    exit 1
fi
echo -e "${GREEN}✓ Firebase CLI found${NC}"

# Check project config
echo
echo "[2/6] Checking Firebase project configuration..."
if [ ! -f ".firebaserc" ]; then
    echo -e "${RED}ERROR: .firebaserc not found.${NC}"
    echo "Please run 'firebase init' first."
    exit 1
fi
echo -e "${GREEN}✓ Firebase project configured${NC}"

# Backup existing indexes
echo
echo "[3/6] Backing up current indexes..."
mkdir -p backups
timestamp=$(date +"%Y%m%d_%H%M")
firebase firestore:indexes --quiet > "backups/firestore_indexes_backup_${timestamp}.json" 2>/dev/null || true
echo -e "${GREEN}✓ Current indexes backed up${NC}"

# Validate new indexes
echo
echo "[4/6] Validating firestore.indexes.json..."
if [ ! -f "firestore.indexes.json" ]; then
    echo -e "${RED}ERROR: firestore.indexes.json not found.${NC}"
    exit 1
fi

# Check JSON syntax
if ! python3 -m json.tool firestore.indexes.json > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Invalid JSON syntax in firestore.indexes.json${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Index configuration is valid${NC}"

# Deploy indexes
echo
echo "[5/6] Deploying Firestore indexes..."
echo -e "${YELLOW}Note: This may take several minutes for large datasets.${NC}"
if firebase deploy --only firestore:indexes; then
    echo -e "${GREEN}✓ Indexes deployed successfully${NC}"
else
    echo -e "${RED}ERROR: Index deployment failed.${NC}"
    echo "Check the error messages above."
    exit 1
fi

# Show deployment status
echo
echo "[6/6] Checking index build status..."
echo
echo "========================================"
echo "Deployment Summary:"
echo "========================================"
echo -e "${GREEN}✓ Firestore indexes deployed${NC}"
echo -e "${GREEN}✓ Backup created in backups/ folder${NC}"
echo
echo -e "${YELLOW}IMPORTANT NOTES:${NC}"
echo "- Index building may take several minutes"
echo "- Check Firebase Console for build progress"
echo "- Old queries will work during index building"
echo "- New optimized queries are now available"
echo
echo "Firebase Console: https://console.firebase.google.com/"
echo

read -p "Press Enter to continue..."
