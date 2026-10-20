#!/usr/bin/env bash

# ==============================================================================
# MotoLogg - Firebase App Distribution Automation Script
# Cleans Flutter, builds a fresh release APK, and uploads it to Firebase.
# Reads release notes from 'releasenotes.md'.
# ==============================================================================

set -eo pipefail

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
APP_ID="1:307266324548:android:8609d0ba88fab165789411"
NOTES_FILE="$SCRIPT_DIR/releasenotes.md"
APK_PATH="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-release.apk"
TESTER_GROUP="DEV"

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"

# ==============================================================================
# Header
# ==============================================================================

echo -e "${BOLD}${CYAN}====================================================${NC}"
echo -e "${BOLD}${CYAN}    🏍️ MotoLogg Firebase App Distribution 🚀${NC}"
echo -e "${BOLD}${CYAN}====================================================${NC}"
echo ""

# ==============================================================================
# 1. Check release notes
# ==============================================================================

if [ ! -f "$NOTES_FILE" ]; then
  echo -e "${RED}❌ Error: Release notes file not found:${NC}"
  echo "$NOTES_FILE"

  echo -e "${YELLOW}Creating a release notes template.${NC}"

  cat <<'EOF' > "$NOTES_FILE"
# MotoLogg Release Notes

- Bug fixes and performance improvements.
EOF

  echo -e "${YELLOW}Please edit releasenotes.md and run the script again.${NC}"
  exit 1
fi

if [ ! -s "$NOTES_FILE" ]; then
  echo -e "${RED}❌ Error: Release notes file is empty.${NC}"
  exit 1
fi

echo -e "${GREEN}📝 Release notes:${NC}"
echo "----------------------------------------------------"
cat "$NOTES_FILE"
echo "----------------------------------------------------"
echo ""

# ==============================================================================
# 2. Check required tools
# ==============================================================================

if ! command -v flutter >/dev/null 2>&1; then
  echo -e "${RED}❌ Flutter is not installed or not in PATH.${NC}"
  exit 1
fi

if ! command -v firebase >/dev/null 2>&1; then
  echo -e "${RED}❌ Firebase CLI is not installed or not in PATH.${NC}"
  echo -e "${YELLOW}Install using: npm install -g firebase-tools${NC}"
  exit 1
fi

if ! command -v du >/dev/null 2>&1; then
  echo -e "${RED}❌ Required command 'du' is unavailable.${NC}"
  exit 1
fi

# ==============================================================================
# 3. Clean Flutter project
# ==============================================================================

echo -e "${CYAN}🧹 Cleaning Flutter project...${NC}"

flutter clean

echo -e "${GREEN}✅ Flutter clean completed!${NC}"
echo ""

# ==============================================================================
# 4. Fetch Flutter dependencies
# ==============================================================================

echo -e "${CYAN}📦 Fetching Flutter dependencies...${NC}"

flutter pub get

echo -e "${GREEN}✅ Dependencies fetched successfully!${NC}"
echo ""

# ==============================================================================
# 5. Build a fresh release APK
# ==============================================================================

echo -e "${CYAN}🔨 Building fresh release APK...${NC}"

flutter build apk --release

echo -e "${GREEN}✅ Release build completed!${NC}"
echo ""

# ==============================================================================
# 6. Verify the APK
# ==============================================================================

if [ ! -f "$APK_PATH" ]; then
  echo -e "${RED}❌ Error: APK not found at:${NC}"
  echo "$APK_PATH"
  exit 1
fi

if [ ! -s "$APK_PATH" ]; then
  echo -e "${RED}❌ Error: APK exists but is empty.${NC}"
  exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)

echo -e "${CYAN}📦 Fresh APK ready:${NC}"
echo "Path: $APK_PATH"
echo -e "Size: ${BOLD}${APK_SIZE}${NC}"
echo ""

# ==============================================================================
# 7. Distribute APK through Firebase App Distribution
# ==============================================================================

echo -e "${CYAN}👥 Target tester group:${NC} $TESTER_GROUP"
echo -e "${CYAN}🚀 Uploading APK to Firebase App Distribution...${NC}"
echo ""

firebase appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --release-notes-file "$NOTES_FILE" \
  --groups "$TESTER_GROUP"

echo ""

# ==============================================================================
# 8. Success
# ==============================================================================

echo -e "${BOLD}${GREEN}🎉 Successfully uploaded to Firebase App Distribution!${NC}"
echo -e "${GREEN}Testers can download the new build through Firebase App Tester or the web portal.${NC}"
