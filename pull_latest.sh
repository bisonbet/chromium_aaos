#!/bin/bash

# This script should be run from $CHROMIUMBUILD/chromium/ directory
# It updates the Chromium source and applies the AAOS patch

# Determine the patch file location
# Priority: 1) Command line arg, 2) chromium_aaos repo, 3) Default location
PATCH_FILE=""

if [[ -n "$1" ]]; then
    # Use provided patch file path
    PATCH_FILE="$1"
elif [[ -n "$CHROMIUMBUILD" ]] && [[ -f "$CHROMIUMBUILD/chromium_aaos/automotive_enhanced.patch" ]]; then
    # Use chromium_aaos repo with enhanced patch
    PATCH_FILE="$CHROMIUMBUILD/chromium_aaos/automotive_enhanced.patch"
elif [[ -f "$HOME/chromium_aaos/automotive_enhanced.patch" ]]; then
    # Check home directory
    PATCH_FILE="$HOME/chromium_aaos/automotive_enhanced.patch"
elif [[ -f "$HOME/chromium/automotive.patch" ]]; then
    # Fallback to old location (for backwards compatibility)
    PATCH_FILE="$HOME/chromium/automotive.patch"
    echo "WARNING: Using legacy automotive.patch. Consider upgrading to automotive_enhanced.patch"
else
    echo "ERROR: Cannot find patch file!"
    echo "Please specify patch file location as argument, or ensure it exists at:"
    echo "  - \$CHROMIUMBUILD/chromium_aaos/automotive_enhanced.patch"
    echo "  - ~/chromium_aaos/automotive_enhanced.patch"
    echo "  - ~/chromium/automotive.patch (legacy)"
    echo ""
    echo "Usage: $0 [path-to-patch-file]"
    exit 1
fi

echo "Using patch file: $PATCH_FILE"

# Verify we're in the correct directory structure
if [[ ! -d "src" ]]; then
    echo "ERROR: 'src' directory not found!"
    echo "This script must be run from \$CHROMIUMBUILD/chromium/ directory"
    echo "Expected directory structure:"
    echo "  \$CHROMIUMBUILD/chromium/"
    echo "    ├── depot_tools/"
    echo "    ├── src/"
    echo "    └── (pull_latest.sh runs here)"
    exit 1
fi

echo "Changing to src directory..."
cd src || { echo "Failed to cd into src directory"; exit 1; }

echo "Fetching latest Chromium changes..."
git fetch

echo "Resetting working tree..."
git reset --hard

echo "Pulling latest changes..."
git pull

echo "Running gclient sync (this may take a while)..."
gclient sync

echo "Applying AAOS patch..."
cp "$PATCH_FILE" ./automotive_temp.patch
if ! git apply automotive_temp.patch; then
    echo "ERROR: Failed to apply patch!"
    echo "This could mean:"
    echo "  1. The patch is already applied"
    echo "  2. The Chromium source has changed and patch needs updating"
    echo "  3. There are conflicts that need manual resolution"
    rm automotive_temp.patch
    exit 1
fi

echo "Cleaning up temporary patch file..."
rm automotive_temp.patch

echo "Running gclient hooks..."
gclient runhooks

echo ""
echo "✓ Successfully updated Chromium source and applied AAOS patch!"
echo "Next steps:"
echo "  1. Navigate to your chromium_aaos repo directory"
echo "  2. Run ./build_release.sh to build"
