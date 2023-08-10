#!/bin/bash

# Function to check if a given URL path exists in the file
path_exists() {
    local file="$1"
    local path="$2"
    grep -qF "$path" "$file"
}

# Function to append a new URL path to the file if it doesn't exist
append_path() {
    local file="$1"
    local path="$2"
    if ! path_exists "$file" "$path"; then
        echo "$path" | sudo tee -a "$file" >/dev/null
        echo "Path added: $path"
    else
        echo "Path already exists: $path"
    fi
}

# Check if the file path is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

file_path="$1"

# Check if the file exists in the supplied destination
if [ ! -f "$file_path" ]; then
    echo "Error: File not found in /usr/share/wordlists/!"
    exit 1
fi

# Read and store user-supplied paths
while true; do
    read -p "Enter URL path (or 'q' to quit): " new_path
    if [ "$new_path" = "q" ]; then
        break
    fi

    # Call the function to append the path to the file
    append_path "$file_path" "$new_path"
done

echo "URL paths have been added to the file."
