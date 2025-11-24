#!/bin/bash

# Usage: ./replace_in_files.sh "old_string" "new_string" [directory]
# If directory is not provided, it defaults to the current directory.

set -euo pipefail  # safer scripting

OLD_STRING="socmel_1"
NEW_STRING="socmel_1"
TARGET_DIR="/home/alberto/socmel_1"


# Confirm with user before proceeding (optional but recommended)
echo "Replacing '${OLD_STRING}' with '${NEW_STRING}' in all files under '${TARGET_DIR}'"
read -rp "Are you sure? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Use find + sed to replace in-place only in regular files
# -print0 and -0 handle filenames with spaces/special chars safely
export OLD_STRING
export NEW_STRING
find "$TARGET_DIR" -type f -print0 | while IFS= read -r -d '' file; do
    # Skip binary files to avoid corruption (basic heuristic)
    if file --mime-type "$file" | grep -q 'text/'; then
        sed -i "s/${OLD_STRING}/${NEW_STRING}/g" "$file"
        echo "Updated: $file"
    fi
done

echo "Replacement complete."