#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_blue()    { echo -e "${BLUE}$1${NC}"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# Check if bump type is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <major|minor|patch>"
    print_info "Example: $0 patch"
    exit 1
fi

BUMP_TYPE=$1
PUBSPEC="pubspec.yaml"
CHANGELOG_FILE="CHANGELOG.md"

if [[ ! "$BUMP_TYPE" =~ ^(major|minor|patch)$ ]]; then
    print_error "Invalid bump type: $BUMP_TYPE"
    print_error "Valid types: major, minor, patch"
    exit 1
fi

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC" ]; then
    print_error "File not found: $PUBSPEC"
    exit 1
fi

# Check if CHANGELOG.md exists
if [ ! -f "$CHANGELOG_FILE" ]; then
    print_warning "$CHANGELOG_FILE not found. Creating it..."
    cat > "$CHANGELOG_FILE" << 'EOF'
# Changelog

All notable changes to this project will be documented in this file.

EOF
fi

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC" | sed 's/version: //')

if [ -z "$CURRENT_VERSION" ]; then
    print_error "Could not find version in $PUBSPEC"
    exit 1
fi

# Parse version (supports formats like 1.2.3 or 1.2.3+4)
VERSION_BASE=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | grep -o '+[0-9]*' | tr -d '+' || echo "")

# Split version into parts
MAJOR=$(echo "$VERSION_BASE" | cut -d'.' -f1)
MINOR=$(echo "$VERSION_BASE" | cut -d'.' -f2)
PATCH=$(echo "$VERSION_BASE" | cut -d'.' -f3)

# Bump version based on type
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"

# Add build number if it existed
if [ -n "$BUILD_NUMBER" ]; then
    NEW_VERSION="$NEW_VERSION+$BUILD_NUMBER"
fi

print_info "Current version: ${CURRENT_VERSION}"
print_info "New version: ${NEW_VERSION}"
echo ""

# Update version in pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version: $CURRENT_VERSION/version: $NEW_VERSION/" "$PUBSPEC"
else
    # Linux
    sed -i "s/^version: $CURRENT_VERSION/version: $NEW_VERSION/" "$PUBSPEC"
fi

# Verify the change
UPDATED_VERSION=$(grep "^version:" "$PUBSPEC" | sed 's/version: //')
if [ "$UPDATED_VERSION" != "$NEW_VERSION" ]; then
    print_error "Failed to update version in $PUBSPEC"
    exit 1
fi

# Update CHANGELOG.md
CURRENT_DATE=$(date +%Y-%m-%d)

# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LAST_TAG" ]; then
    COMMITS=$(git log ${LAST_TAG}..HEAD --pretty=format:"* %s" --no-merges)
else
    print_info "No previous tag found, collecting all commits..."
    COMMITS=$(git log --pretty=format:"* %s" --no-merges)
fi

# If there are no commits, add a generic entry
if [ -z "$COMMITS" ]; then
    COMMITS="* Version bump"
fi

# Create new CHANGELOG entry
NEW_CHANGELOG_ENTRY="## $NEW_VERSION - $CURRENT_DATE
$COMMITS

"

# Prepend to CHANGELOG
TEMP_FILE=$(mktemp)
echo "$NEW_CHANGELOG_ENTRY" > $TEMP_FILE
cat "$CHANGELOG_FILE" >> $TEMP_FILE
mv $TEMP_FILE "$CHANGELOG_FILE"

# Open CHANGELOG for editing
if [ -n "$EDITOR" ]; then
    $EDITOR "$CHANGELOG_FILE"
elif command -v xdg-open &> /dev/null; then
    xdg-open "$CHANGELOG_FILE" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$CHANGELOG_FILE"
else
    print_warning "Could not detect preferred editor. Please open $CHANGELOG_FILE manually."
fi

print_warning "================================================"
print_warning "Please review and edit $CHANGELOG_FILE before committing"
print_warning "Press ENTER when done to continue..."
print_warning "================================================"
read -r

# Git commit and tag
print_info "Creating git commit and tag..."
git add "$PUBSPEC" "$CHANGELOG_FILE"
git commit -m "$NEW_VERSION"
git tag -a "v${NEW_VERSION}" -m "$NEW_VERSION"

echo ""
print_success "Version bumped successfully!"
echo -e "   From: ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "   To:   ${GREEN}$NEW_VERSION${NC}"
echo ""
print_info "Next step to publish:"
print_blue "   git push --follow-tags"
