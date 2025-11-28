#!/bin/bash
# Add custom icons or background images to Homepage dashboard
#
# Usage:
#   ./scripts/homepage-add-icon.sh /path/to/icon.png
#   ./scripts/homepage-add-icon.sh --background /path/to/background.jpg
#   ./scripts/homepage-add-icon.sh --list
#   ./scripts/homepage-add-icon.sh --delete icon.png
#
# Icons: available as /icons/filename.png
# Backgrounds: available as /images/filename.jpg

set -e

NAMESPACE="homepage"
POD_LABEL="app.kubernetes.io/name=homepage"
ICONS_PATH="/app/public/icons"
IMAGES_PATH="/app/public/images"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [OPTIONS] [FILE...]"
    echo ""
    echo "Add custom icons or background images to Homepage dashboard"
    echo ""
    echo "Options:"
    echo "  --background, -b  Add as background image (to /images/)"
    echo "  --list, -l        List all custom icons and images"
    echo "  --delete, -d      Delete an icon by name"
    echo "  --delete-bg       Delete a background image by name"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 myicon.png                       # Add icon"
    echo "  $0 -b forest.jpg                    # Add background image"
    echo "  $0 --list                           # List all assets"
    echo "  $0 --delete myicon.png              # Delete an icon"
    echo "  $0 --delete-bg background.jpg       # Delete a background"
    echo ""
    echo "Reference in Homepage config:"
    echo "  Icons:       icon: /icons/myicon.png"
    echo "  Backgrounds: background: /images/forest.jpg"
}

get_pod() {
    kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null
}

list_assets() {
    local pod
    pod=$(get_pod)

    if [[ -z "$pod" ]]; then
        echo -e "${RED}Error: Homepage pod not found${NC}"
        exit 1
    fi

    echo -e "${CYAN}=== Custom Icons (/icons/) ===${NC}"
    kubectl exec -n "$NAMESPACE" "$pod" -- ls -la "$ICONS_PATH" 2>/dev/null || echo "  (none)"
    echo ""
    echo -e "${CYAN}=== Background Images (/images/) ===${NC}"
    kubectl exec -n "$NAMESPACE" "$pod" -- ls -la "$IMAGES_PATH" 2>/dev/null || echo "  (none)"
}

delete_asset() {
    local asset_name="$1"
    local asset_path="$2"
    local pod
    pod=$(get_pod)

    if [[ -z "$pod" ]]; then
        echo -e "${RED}Error: Homepage pod not found${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Deleting: $asset_name${NC}"
    kubectl exec -n "$NAMESPACE" "$pod" -- rm -f "$asset_path/$asset_name"
    echo -e "${GREEN}Deleted: $asset_name${NC}"
}

add_asset() {
    local file="$1"
    local dest_path="$2"
    local asset_type="$3"
    local pod
    pod=$(get_pod)

    if [[ -z "$pod" ]]; then
        echo -e "${RED}Error: Homepage pod not found${NC}"
        exit 1
    fi

    if [[ ! -f "$file" ]]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        return 1
    fi

    local filename
    filename=$(basename "$file")

    echo -e "${YELLOW}Adding $asset_type: $filename${NC}"
    kubectl cp "$file" "$NAMESPACE/$pod:$dest_path/$filename"
    echo -e "${GREEN}Added: $filename${NC}"

    if [[ "$asset_type" == "icon" ]]; then
        echo -e "  Use in services.yaml as: ${CYAN}icon: /icons/$filename${NC}"
    else
        echo -e "  Use in settings.yaml as: ${CYAN}background: /images/$filename${NC}"
    fi
}

# Parse arguments
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

BACKGROUND_MODE=false

case "$1" in
    --help|-h)
        usage
        exit 0
        ;;
    --list|-l)
        list_assets
        exit 0
        ;;
    --delete|-d)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Please specify an icon name to delete${NC}"
            exit 1
        fi
        delete_asset "$2" "$ICONS_PATH"
        exit 0
        ;;
    --delete-bg)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Please specify an image name to delete${NC}"
            exit 1
        fi
        delete_asset "$2" "$IMAGES_PATH"
        exit 0
        ;;
    --background|-b)
        BACKGROUND_MODE=true
        shift
        ;;
esac

# Add files
if [[ $# -eq 0 ]]; then
    echo -e "${RED}Error: No files specified${NC}"
    usage
    exit 1
fi

for file in "$@"; do
    if [[ "$BACKGROUND_MODE" == true ]]; then
        add_asset "$file" "$IMAGES_PATH" "background"
    else
        add_asset "$file" "$ICONS_PATH" "icon"
    fi
done

echo ""
echo -e "${GREEN}Done! Assets are immediately available.${NC}"
if [[ "$BACKGROUND_MODE" == true ]]; then
    echo -e "${YELLOW}Note: You may need to restart Homepage for background changes to take effect.${NC}"
fi
