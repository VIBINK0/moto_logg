#!/usr/bin/env bash

# ==============================================================================
# MotoLogg - Firebase App Distribution Automation Script
# Reads release notes from 'releasenotes.md' and uploads the release APK.
# ==============================================================================

set -eo pipefail

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
APP_ID="1:307266324548:android:8609d0ba88fab165789411"
NOTES_FILE="$SCRIPT_DIR/releasenotes.md"
APK_PATH="$SCRIPT_DIR/build/app/outputs/flutter-apk/app-release.apk"
SKIP_BUILD=false
TESTER_GROUP="DEV"

# Text formatting
BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --skip-build|-s)
      SKIP_BUILD=true
      shift
      ;;
    --help|-h)
      echo -e "${BOLD}Usage:${NC} ./distribute.sh [options]"
      echo ""
      echo "Options:"
      echo "  -s, --skip-build       Skip 'flutter build apk --release' and upload existing APK"
      echo "  -h, --help             Display this help message"
      echo ""
      echo "Target Group: DEV"
      exit 0
      ;;
    *)
      echo -e "${YELLOW}Warning: Unknown argument '$1' ignored.${NC}"
      shift
      ;;
  esac
done

echo -e "${BOLD}${CYAN}====================================================${NC}"
echo -e "${BOLD}${CYAN}    🏍️  MotoLogg Firebase App Distribution  🚀       ${NC}"
echo -e "${BOLD}${CYAN}====================================================${NC}"
echo ""

# 1. Check release notes file
if [ ! -f "$NOTES_FILE" ]; then
  echo -e "${RED}❌ Error: Release notes file not found at: $NOTES_FILE${NC}"
  echo -e "${YELLOW}Creating a blank releasenotes.md for you. Please edit it and re-run.${NC}"
  cat << 'EOF' > "$NOTES_FILE"
# MotoLogg Release Notes

- Bug fixes and performance improvements.
EOF
  exit 1
fi

echo -e "${GREEN}📝 Found release notes in releasenotes.md:${NC}"
echo "----------------------------------------------------"
cat "$NOTES_FILE"
echo "----------------------------------------------------"
echo ""

# 2. Check Firebase CLI
if ! command -v firebase &> /dev/null; then
  echo -e "${RED}❌ Firebase CLI ('firebase') is not installed or not in PATH.${NC}"
  echo -e "${YELLOW}Install it using: npm install -g firebase-tools${NC}"
  exit 1
fi

# 3. Build Release APK (unless skipped)
if [ "$SKIP_BUILD" = true ]; then
  echo -e "${YELLOW}⏩ Skipping build step (--skip-build specified).${NC}"
  if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ Error: No release APK found at $APK_PATH!${NC}"
    echo -e "${YELLOW}Run without --skip-build first to compile the APK.${NC}"
    exit 1
  fi
else
  echo -e "${CYAN}🔨 Building release APK (flutter build apk --release)...${NC}"
  flutter build apk --release
  echo -e "${GREEN}✅ Build complete!${NC}"
fi

# Verify APK exists
if [ ! -f "$APK_PATH" ]; then
  echo -e "${RED}❌ Error: APK not found at: $APK_PATH${NC}"
  exit 1
fi

APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "${CYAN}📦 APK ready:${NC} $APK_PATH (${BOLD}${APK_SIZE}${NC})"
echo ""

# 4. Construct Firebase distribution command
DISTRIBUTE_CMD=(firebase appdistribution:distribute "$APK_PATH" --app "$APP_ID" --release-notes-file "$NOTES_FILE" --groups "DEV")

echo -e "${CYAN}👥 Distributing to group:${NC} DEV"
echo -e "${CYAN}🚀 Uploading APK to Firebase App Distribution...${NC}"
"${DISTRIBUTE_CMD[@]}"

echo ""
echo -e "${BOLD}${GREEN}🎉 Successfully uploaded to Firebase App Distribution!${NC}"
echo -e "${GREEN}Testers can now download the new build directly from the Firebase App Tester app or web portal.${NC}"
