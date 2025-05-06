#!/bin/bash

# --- Configuration ---
search_dir="${1:-.}" # Directory to search in. Defaults to current directory "."

# --- Check prerequisites ---
command -v jq >/dev/null 2>&1 || { echo >&2 "Error: jq is required (version 1.4+ recommended). Aborting."; exit 1; }
command -v find >/dev/null 2>&1 || { echo >&2 "Error: find command is required. Aborting."; exit 1; }
command -v basename >/dev/null 2>&1 || { echo >&2 "Error: basename command is required. Aborting."; exit 1; }
command -v dirname >/dev/null 2>&1 || { echo >&2 "Error: dirname command is required. Aborting."; exit 1; }

# --- Argument Check ---
if [ ! -d "$search_dir" ]; then
    echo "Error: Directory '$search_dir' not found."
    echo "Usage: $0 [path_to_modules_directory]"
    exit 1
fi

echo "Searching for module.json files in: $search_dir"
echo "*** CRITICAL WARNING ***"
echo "This script modifies module.json files in place (author, id, packs.type, legacy name)."
echo "Ensure you have a reliable backup of your '$search_dir' directory before proceeding."
read -p "Press Enter to continue or Ctrl+C to CANCEL NOW..."

# --- Main Processing Loop ---
find "$search_dir" -name module.json -type f -print0 | while IFS= read -r -d $'\0' file; do
    echo "----------------------------------------"
    echo "Processing: $file"
    temp_file="${file}.tmp" # Define temp file name

    # Attempt to determine the module ID from the directory name
    module_dir_name=$(basename "$(dirname "$file")")
    # echo "  Inferred directory/module ID: $module_dir_name" # Optional: uncomment for debug

    # Define the jq transformation script
    # 1. Fix author -> authors
    # 2. Add 'id' field using directory name IF 'id' is missing
    # 3. Fix packs: add 'type' from 'entity' if 'type' is missing, remove 'entity'
    # 4. Remove legacy top-level 'name' field
    jq_script='
      # Fix author -> authors
      (if has("author") and (has("authors") | not) then
         .authors = [{"name": (if .author != null then .author else "Unknown" end), "email": "", "url": ""}] | del(.author)
       elif has("author") and has("authors") then # Cleanup if both exist
         del(.author)
       else
         .
       end)
      # Add ID from directory name if missing (passed as $moduleId)
      | (if has("id") | not then .id = $moduleId else . end)
      # Update packs array: entity -> type (V11+)
      | (if has("packs") and (.packs | type == "array") then
           .packs = (.packs | map(
             if has("entity") and (has("type") | not) then
               . + {"type": .entity} | del(.entity) # Add type from entity, delete entity
             else
               . # No change needed for this pack item
             end
           ))
         else
           . # No packs array or not an array, do nothing
         end)
      # Remove legacy top-level "name" key if it exists
      | del(.name)
    '

    # Run jq with the script, passing the directory name as an argument
    jq --arg moduleId "$module_dir_name" "$jq_script" "$file" > "$temp_file"

    # Check if jq succeeded and temp file was created and is not empty
    if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
        # Validate JSON structure before replacing
        if jq -e . "$temp_file" > /dev/null; then
             # Replace original file
             mv "$temp_file" "$file"
             if [ $? -eq 0 ]; then
                  echo "  Successfully updated and fixed '$file'"
             else
                  echo "  Error: Failed to replace '$file' with temporary file."
                  rm -f "$temp_file" # Clean up temp file on move error
             fi
        else
             echo "  Error: jq produced invalid JSON for '$file'. Original file unmodified."
             rm -f "$temp_file" # Clean up invalid temp file
        fi
    elif [ -f "$temp_file" ]; then
         echo "  Error: jq produced an empty file for '$file'. Original file unmodified."
         rm -f "$temp_file" # Clean up empty temp file
    else
         echo "  Error: Failed processing '$file' with jq. Original file unmodified."
         # temp_file likely wasn't created
    fi

done

echo "----------------------------------------"
echo "Script finished. Please check Foundry VTT for remaining errors."
