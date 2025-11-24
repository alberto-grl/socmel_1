#!/bin/bash

# ------------------------------------------------------------
# File Copy Script Template
# Edit the variables below to match your requirements
# ------------------------------------------------------------

# Source and destination root paths
FROM_PATH="$HOME/socmel_1"
TO_PATH="$HOME/socmel_1"

# Add your specific files/directories to copy below
# Format: copy_item "source_relative_path" "destination_relative_path"
# If destination is omitted, it will use the same relative path as source


copy_item() {
    local src_rel="$1"
    local dest_rel="${2:-$1}"

    local src_full="$FROM_PATH/$src_rel"
    local dest_full="$TO_PATH/$dest_rel"

    if [[ ! -e "$src_full" ]]; then
        echo "Warning: Source not found - $src_full"
        return 1
    fi

    local dest_parent
    dest_parent="$(dirname "$dest_full")"

    if [[ -d "$src_full" ]]; then
        # Ensure parent directory exists
        mkdir -p "$dest_parent"

        # Remove existing destination (to avoid nesting and ensure clean copy)
        if [[ -e "$dest_full" ]]; then
            rm -rf "$dest_full"
        fi

        echo "Copying directory: $src_rel -> $dest_rel"
        cp -r "$src_full" "$dest_full"
    else
        # For files: ensure parent exists and copy
        mkdir -p "$dest_parent"
        echo "Copying file: $src_rel -> $dest_rel"
        cp "$src_full" "$dest_full"
    fi
}

# ------------------------------------------------------------
# MAIN COPY SECTION - EDIT THIS PART
# ------------------------------------------------------------

# Example entries (uncomment and modify as needed):

# Copy entire directory with same name
  copy_item "litex/litex/soc/software/socmel_1/"
  copy_item "litex-boards/litex_boards/targets/socmel_1/"
# Don't use trailing / for single files 
  copy_item "litex-boards/litex_boards/platforms/sipeed_tang_primer_20k_socmel_1.py" 
  copy_item "bin/litex_make_sdr_v1"
  copy_item "bin/socmel_1_scripts""


# Copy single file
# copy_item "file.txt"

# Copy file to different name/location
# copy_item "config/original.conf" "settings/my.conf"

# Copy multiple items
# copy_item "docs"
# copy_item "src/main.py"
# copy_item "data/input.csv" "inputs/data.csv"

# ------------------------------------------------------------
# Add your copy commands here:
# ------------------------------------------------------------

# YOUR COPY COMMANDS GO HERE
# Example:
# copy_item "bin"
# copy_item "lib/python3.*/site-packages/litex"  # Note: wildcards may not work as expected
# copy_item "requirements.txt"

# ------------------------------------------------------------
# End of user configuration
# ------------------------------------------------------------

echo "Copy operations completed!"