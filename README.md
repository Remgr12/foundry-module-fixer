# Foundry VTT Module Manifest Fixer

This bash script attempts to automatically fix common compatibility issues found in `module.json` files for Foundry VTT modules. It's particularly useful for updating older modules to meet the structural requirements of newer Foundry VTT versions (e.g., V11, V12, V13+).

## Purpose

Foundry VTT's manifest format (`module.json`) for modules and systems has evolved. Older modules may use deprecated fields or lack newly required fields, which can lead to errors or prevent them from loading correctly in the latest versions of Foundry VTT. This script aims to address several of the most common structural manifest issues to improve compatibility.

## Fixes Applied by `fix.sh`

The script iterates through `module.json` files found in a specified directory (and its subdirectories) and applies the following changes **in place**:

1.  **Author Field (`author` vs `authors`):**
    * Converts the legacy single `author` string field to the current `authors` array format (e.g., `{"authors": [{"name": "Original Author Name", "email": "", "url": ""}]}`).
    * If the original `author` field is empty or null, it defaults the name to "Unknown Author".
    * If both `author` and `authors` fields happen to exist, it removes the legacy `author` field to prevent conflicts.
2.  **Module ID (`id` field):**
    * Ensures an `id` field is present at the root of the manifest.
    * If the `id` field is missing, it uses the name of the module's parent directory as the `id` (e.g., a module in the directory `my-cool-module` would get `"id": "my-cool-module"`).
3.  **Compendium Packs (`packs` field - for V11+):**
    * For each compendium pack defined in the `packs` array:
        * If a pack definition has an `entity` field (older format) but is missing the `type` field (newer format), the script creates the `type` field using the value from `entity` and then deletes the old `entity` field. This is crucial for compatibility with Foundry VTT version 11 and newer.
4.  **Legacy Top-Level `name` Field:**
    * Removes the deprecated top-level `name` field if it exists. In modern manifests, `id` is used as the unique machine-readable identifier, and `title` is used for the human-readable display name.

## Prerequisites

To run this script successfully, you will need the following command-line tools installed on your system (typically Linux or macOS):

* **`bash`**: The script is written for the bash shell.
* **`jq`**: A powerful command-line JSON processor. Version 1.4 or newer is generally recommended for some of the fallback logic, though the script aims for broad compatibility.
    * *Typical Installation (Linux):* `sudo apt update && sudo apt install jq` or `sudo dnf install jq`
    * *Typical Installation (macOS with Homebrew):* `brew install jq`
* **`find`**: Standard Unix utility for finding files (usually pre-installed).
* **`basename`**: Standard Unix utility for stripping directory information (usually pre-installed).
* **`dirname`**: Standard Unix utility for extracting the directory portion of a path (usually pre-installed).

## Installation / Setup

1.  **Get the Script:**
    * Download the `fix.sh` script file to your computer.
    * If you are setting up a Git repository for it, clone the repository.
2.  **Make it Executable:**
    Navigate to the directory where you saved `fix.sh` using your terminal and run the following command to make it executable:
    ```bash
    chmod +x fix.sh
    ```

## Usage

Run the script from your terminal. You can optionally provide a target directory where the script should search for `module.json` files. If no directory is specified, it defaults to scanning the current directory (`.`) and all its subdirectories.

**Syntax:**
```bash
./fix.sh
```
```bash
./fix.sh [target_directory]
```
