#!/bin/bash

url="$1"

# Extract the file ID from the URL
file_id=$(echo "$url" | awk -F'[=/]' '/\/d\/[a-zA-Z0-9_-]*\/?/{print $6}')

if [ -z "$file_id" ]; then
    echo "Invalid Google Drive URL. Please provide a valid URL."
    exit 1
fi

echo "FILE ID IS: $file_id"
echo ""

# Generate the new URL
new_url="https://docs.google.com/document/d/$file_id/export?format=pdf"
echo "New URL: $new_url"
echo ""

# Encode the new URL for use in the Google Docs Viewer URL
# encoded_url=$(echo "$new_url" | sed 's/\//%2F/g')
# echo "Encoded URL: $encoded_url"
# echo ""

# Generate the final URL for viewing the document in the Google Docs Viewer
final_url="https://docs.google.com/viewer?url=$new_url"

echo "FINAL URL: $final_url"
echo ""
