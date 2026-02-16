#!/bin/bash

# Target line to remove
TARGET_LINE='@define-color launcher @primary;'

echo "Starting cleanup of .css files..."

# Loop through all .css files in the current directory
for file in *.css; do
    # Check if files exist to avoid errors in empty directories
    [ -e "$file" ] || continue

    echo "Processing: $file"

    # Use sed to delete the line. 
    # -i: edit in-place
    # /pattern/d: find the pattern and delete the entire line
    sed -i "/$TARGET_LINE/d" "$file"
done

echo "Done! All instances of that line have been removed."