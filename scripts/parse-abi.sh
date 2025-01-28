#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq to use this script."
    exit 1
fi

# Check if file name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <abi-file.json>"
    exit 1
fi

# Read the ABI file
ABI_FILE="$1"

if [ ! -f "$ABI_FILE" ]; then
    echo "File not found: $ABI_FILE"
    exit 1
fi

# Parse readable and writable functions
readable_functions=$(jq -r '.abi[] | select(.type == "function" and (.stateMutability == "view" or .stateMutability == "pure")) | "- **" + .name + "(" + (if .inputs then (.inputs | map(.type + " " + .name) | join(", ")) else "" end) + ")**: `" + (if .outputs then (.outputs | map(.type) | join(", ")) else "void" end) + "`"' "$ABI_FILE")

writable_functions=$(jq -r '.abi[] | select(.type == "function" and (.stateMutability != "view" and .stateMutability != "pure")) | "- **" + .name + "(" + (if .inputs then (.inputs | map(.type + " " + .name) | join(", ")) else "" end) + ")**: `" + (if .outputs then (.outputs | map(.type) | join(", ")) else "void" end) + "`"' "$ABI_FILE")

# Print in Markdown format
echo "### Readable Functions (Pure/View)"
if [ -z "$readable_functions" ]; then
    echo "No readable functions found."
else
    echo "$readable_functions"
fi

echo ""
echo "### Writable Functions (Non-Pure/Non-View)"
if [ -z "$writable_functions" ]; then
    echo "No writable functions found."
else
    echo "$writable_functions"
fi
