#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Bumping iOS SDK version${NC}"
echo ""

PODSPEC="ios/verisoul_sdk.podspec"

# Check if podspec exists
if [ ! -f "$PODSPEC" ]; then
    echo -e "${RED}Error: $PODSPEC not found${NC}"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(grep "s.dependency 'VerisoulSDK'" "$PODSPEC" | sed -n "s/.*'VerisoulSDK', '\([0-9.a-zA-Z-]*\)'.*/\1/p")

if [ -z "$CURRENT_VERSION" ]; then
    echo -e "${RED}Error: Could not find current iOS SDK version in $PODSPEC${NC}"
    exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Fetch latest version from GitHub repo
echo -e "${YELLOW}Fetching latest version from verisoul/native-ios-sdk...${NC}"
LATEST_TAG=$(git ls-remote --tags --sort='v:refname' https://github.com/verisoul/native-ios-sdk.git | tail -n1 | sed 's/.*refs\/tags\/v//' | sed 's/\^{}//')

if [ -z "$LATEST_TAG" ]; then
    echo -e "${RED}Error: Could not fetch latest version from GitHub${NC}"
    exit 1
fi

NEW_VERSION="$LATEST_TAG"

echo "Latest version: $NEW_VERSION"
echo ""

# Check if already up to date
if [ "$CURRENT_VERSION" = "$NEW_VERSION" ]; then
    echo -e "${GREEN}Already up to date!${NC}"
    exit 0
fi

# Update version in podspec
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/s.dependency 'VerisoulSDK', '$CURRENT_VERSION'/s.dependency 'VerisoulSDK', '$NEW_VERSION'/" "$PODSPEC"
else
    # Linux
    sed -i "s/s.dependency 'VerisoulSDK', '$CURRENT_VERSION'/s.dependency 'VerisoulSDK', '$NEW_VERSION'/" "$PODSPEC"
fi

echo -e "${GREEN}Updated $PODSPEC${NC}"

# Run flutter pub upgrade to refresh dependencies
echo ""
echo -e "${YELLOW}Running flutter pub upgrade...${NC}"
if command -v flutter &> /dev/null; then
    if flutter pub upgrade 2>&1 | grep -q "Changed\|Got dependencies"; then
        echo -e "${GREEN}Flutter dependencies upgraded${NC}"
    else
        echo -e "${YELLOW}Could not upgrade Flutter dependencies${NC}"
        echo -e "${YELLOW}Dependencies will be pulled during CI build${NC}"
    fi
else
    echo -e "${YELLOW}Flutter not installed${NC}"
    echo -e "${YELLOW}Dependencies will be pulled during CI build${NC}"
fi

# Update CocoaPods if available
echo ""
echo -e "${YELLOW}Updating CocoaPods dependencies...${NC}"
if command -v pod &> /dev/null; then
    # Update example app Podfile.lock if exists
    if [ -f "example/ios/Podfile" ]; then
        cd example/ios
        if pod update VerisoulSDK 2>&1 | grep -q "Installing\|Pod installation complete"; then
            echo -e "${GREEN}CocoaPods dependencies updated in example/ios${NC}"
            cd ../..
            # Stage the updated Podfile.lock
            git add example/ios/Podfile.lock 2>/dev/null || true
        else
            echo -e "${YELLOW}Could not update CocoaPods in example/ios${NC}"
            echo -e "${YELLOW}You may need to run: cd example/ios && pod update VerisoulSDK${NC}"
            cd ../..
        fi
    else
        echo -e "${YELLOW}No example/ios/Podfile found${NC}"
        echo -e "${YELLOW}Dependencies will be pulled during CI build${NC}"
    fi
else
    echo -e "${YELLOW}CocoaPods not installed${NC}"
    echo -e "${YELLOW}Dependencies will be pulled during CI build${NC}"
fi

# Commit changes
echo ""
git add "$PODSPEC"
git add pubspec.lock 2>/dev/null || true
git commit -m "Update verisoul/native-ios-sdk to version $NEW_VERSION"

echo ""
echo -e "${GREEN}iOS SDK version bumped successfully!${NC}"
echo -e "${GREEN}$CURRENT_VERSION -> $NEW_VERSION${NC}"
echo ""
echo "Next steps:"
echo "1. Run: make release-patch (or release-minor/release-major)"
echo "2. Push changes: git push --follow-tags"
