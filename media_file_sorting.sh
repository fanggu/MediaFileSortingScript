#!/bin/bash

# =========================================
#Photo and Video Sorting Script
# =========================================

# Script Version: 1.0

# -----------------------------------------
# Usage:
# ./script.sh [options] /path/to/source/photos
#
# Options:
#   --dryrun           Simulate actions without making changes
#   --force            Restore files before sorting again
#   --restore          Restore files to original locations
#   --help             Display help message
#   --extensions       Specify additional file extensions to include
#   --exclude-dirs     Exclude specified directories from processing
#   --no-prompt        Do not prompt for confirmations
# -----------------------------------------

# =========================================
# Initialization of Variables
# =========================================

DRYRUN=false
FORCE=false
RESTORE=false
HELP=false
NO_PROMPT=false
EXTRA_EXTENSIONS=()
EXCLUDE_DIRS=()
SOURCE_DIR=""
TARGET_DIR=""
LOG_FILE=""
SORTED_FLAG=""
LOCK_FILE=""
PROCESSED_FILES=()
CREATED_DIRS=()
SUPPORTED_EXTENSIONS=(jpg jpeg png cr2 cr3 nef arw rw2 orf raf dng mov mp4 avi mkv wmv flv mpeg mpg)

# =========================================
# Function to Display Help Message
# =========================================

display_help() {
    echo "Usage: $0 [options] /path/to/source/photos"
    echo
    echo "Options:"
    echo "  --dryrun           Simulate actions without making changes"
    echo "  --force            Restore files before sorting again"
    echo "  --restore          Restore files to original locations"
    echo "  --help             Display this help message"
    echo "  --extensions ext1,ext2  Specify additional file extensions to include"
    echo "  --exclude-dirs dir1,dir2  Exclude specified directories from processing"
    echo "  --no-prompt        Do not prompt for confirmations"
    exit 0
}

# =========================================
# Parse Command-Line Arguments
# =========================================

while [[ "$1" =~ ^- ]]; do
    case "$1" in
        --dryrun)
            DRYRUN=true
            ;;
        --force)
            FORCE=true
            ;;
        --restore)
            RESTORE=true
            ;;
        --help)
            display_help
            ;;
        --no-prompt)
            NO_PROMPT=true
            ;;
        --extensions)
            shift
            IFS=',' read -ra EXTRA_EXTENSIONS <<< "$1"
            ;;
        --exclude-dirs)
            shift
            IFS=',' read -ra EXCLUDE_DIRS <<< "$1"
            ;;
        *)
            echo "Unknown option: $1"
            display_help
            ;;
    esac
    shift
done

# =========================================
# Get the Source Directory
# =========================================

SOURCE_DIR="$1"

if [ -z "$SOURCE_DIR" ]; then
    echo "Error: Source directory not specified."
    display_help
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory does not exist."
    exit 1
fi

# Convert SOURCE_DIR to absolute path
SOURCE_DIR="$(cd "$SOURCE_DIR"; pwd)"

# =========================================
# Set Target Directory and Paths
# =========================================

TARGET_DIR="$SOURCE_DIR/sorted_output"
LOG_FILE="$SOURCE_DIR/sorted_files.log"
SORTED_FLAG="$SOURCE_DIR/.sorted_done"
LOCK_FILE="$SOURCE_DIR/.sorting_lock"

# =========================================
# Function to Acquire Lock
# =========================================

acquire_lock() {
    if [ -e "$LOCK_FILE" ]; then
        echo "Another instance of the script is running. Exiting."
        exit 1
    else
        touch "$LOCK_FILE"
    fi
}

# =========================================
# Function to Release Lock
# =========================================

release_lock() {
    rm -f "$LOCK_FILE"
}

# Trap to ensure the lock is released on exit
trap release_lock EXIT

# Acquire lock
acquire_lock

# =========================================
# Function to Confirm Action
# =========================================

confirm_action() {
    if [ "$NO_PROMPT" = true ]; then
        return 0
    fi
    read -p "$1 [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    else
        return 0
    fi
}

# =========================================
# Function to Restore Files
# =========================================

restore_files() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "No log file found to restore from."
        return
    fi

    if [ "$DRYRUN" = false ] && [ "$NO_PROMPT" = false ]; then
        if ! confirm_action "Are you sure you want to restore files?"; then
            echo "Restore aborted by user."
            exit 1
        fi
    fi

    while IFS= read -r line; do
        source_path="$(echo "$line" | awk -F' -> ' '{print $1}')"
        target_path="$(echo "$line" | awk -F' -> ' '{print $2}')"

        target_full_path="$SOURCE_DIR/$target_path"
        dest_full_path="$SOURCE_DIR/$source_path"

        if [ ! -f "$target_full_path" ]; then
            echo "File not found: $target_full_path. Skipping."
            continue
        fi

        # Ensure destination directory exists
        dest_dir="$(dirname "$dest_full_path")"
        if [ ! -d "$dest_dir" ]; then
            if [ "$DRYRUN" = true ]; then
                echo "[DRYRUN] Would create directory: $dest_dir"
            else
                mkdir -p "$dest_dir"
                echo "Created directory: $dest_dir"
            fi
        fi

        # Handle file conflicts
        if [ -f "$dest_full_path" ]; then
            base_name="$(basename "$dest_full_path")"
            dest_dir="$(dirname "$dest_full_path")"
            extension="${base_name##*.}"
            filename="${base_name%.*}"
            counter=1
            while [ -f "$dest_dir/${filename}_restore_$counter.$extension" ]; do
                ((counter++))
            done
            dest_full_path="$dest_dir/${filename}_restore_$counter.$extension"
        fi

        if [ "$DRYRUN" = true ]; then
            echo "[DRYRUN] Would move file: $target_full_path back to $dest_full_path"
        else
            mv "$target_full_path" "$dest_full_path"
            echo "Moved $target_full_path back to $dest_full_path"
        fi
    done < "$LOG_FILE"

    # Remove sorted_output directory and sorted flag
    if [ "$DRYRUN" = true ]; then
        echo "[DRYRUN] Would remove directory: $TARGET_DIR"
        echo "[DRYRUN] Would remove flag file: $SORTED_FLAG"
        echo "[DRYRUN] Would remove log file: $LOG_FILE"
    else
        rm -rf "$TARGET_DIR"
        rm -f "$SORTED_FLAG" "$LOG_FILE"
        echo "Removed sorted directory, flag file, and log file."
    fi

    echo "Restore complete."
}

# =========================================
# If --restore is Present, Restore Files
# =========================================

if [ "$RESTORE" = true ]; then
    restore_files
    exit 0
fi

# =========================================
# If --force is Present, Restore Before Sorting
# =========================================

if [ "$FORCE" = true ]; then
    echo "Force option detected. Restoring files before sorting again."
    restore_files
fi

# =========================================
# Check If Already Sorted
# =========================================

if [ -f "$SORTED_FLAG" ]; then
    echo "This folder has already been sorted. Use --force to sort again."
    exit 1
fi

# =========================================
# Pre-Execution Checks
# =========================================

# Check write permissions
if [ ! -w "$SOURCE_DIR" ]; then
    echo "Error: No write permission in source directory."
    exit 1
fi

# Check disk space (approximate)
REQUIRED_SPACE=$(du -s "$SOURCE_DIR" | awk '{print $1}')
AVAILABLE_SPACE=$(df "$SOURCE_DIR" | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    echo "Warning: Insufficient disk space. Sorting may fail."
    if [ "$NO_PROMPT" = false ]; then
        if ! confirm_action "Do you want to continue?"; then
            echo "Operation aborted by user."
            exit 1
        fi
    fi
fi

# =========================================
# Combine Supported Extensions
# =========================================

if [ "${#EXTRA_EXTENSIONS[@]}" -ne 0 ]; then
    SUPPORTED_EXTENSIONS+=("${EXTRA_EXTENSIONS[@]}")
fi

# Build find expression for supported extensions
FIND_EXTENSIONS=""
for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
    FIND_EXTENSIONS+=" -iname '*.${ext}' -o"
done
# Remove trailing -o
FIND_EXTENSIONS="${FIND_EXTENSIONS% -o}"

# =========================================
# Exclude Specified Directories
# =========================================

EXCLUDE_PATHS=()
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_PATHS+=("-path '$SOURCE_DIR/$dir' -prune -o")
done

# Build find command
FIND_CMD="find \"$SOURCE_DIR\""
for exclude in "${EXCLUDE_PATHS[@]}"; do
    FIND_CMD+=" $exclude"
done
FIND_CMD+=" -type f \\( $FIND_EXTENSIONS \\)"

# =========================================
# Create Target Directory
# =========================================

if [ "$DRYRUN" = true ]; then
    echo "[DRYRUN] Would create target directory: $TARGET_DIR"
else
    mkdir -p "$TARGET_DIR"
    echo "Created target directory: $TARGET_DIR"
fi

# Initialize the log file
if [ "$DRYRUN" = false ]; then
    > "$LOG_FILE"
fi

# =========================================
# Function to Move Files
# =========================================

move_file() {
    local file="$1"
    local target_dir="$2"

    base_name="$(basename "$file")"
    target_file="$target_dir/$base_name"

    # Counter logic to handle existing files
    counter=1
    while [ -e "$target_file" ]; do
        extension="${base_name##*.}"
        filename="${base_name%.*}"
        target_file="$target_dir/${filename}_$counter.$extension"
        ((counter++))
    done

    if [ "$DRYRUN" = true ]; then
        echo "[DRYRUN] Would move file: $file to $target_file"
    else
        mkdir -p "$target_dir"
        mv "$file" "$target_file"
        echo "Moved $file to $target_file"
        # Log relative paths
        rel_source="${file#$SOURCE_DIR/}"
        rel_target="${target_file#$SOURCE_DIR/}"
        echo "$rel_source -> $rel_target" >> "$LOG_FILE"
    fi
}

# =========================================
# Function to Create Directories
# =========================================

create_dir() {
    local dir="$1"
    if [[ ! " ${CREATED_DIRS[@]} " =~ " $dir " ]]; then
        if [ "$DRYRUN" = true ]; then
            echo "[DRYRUN] Would create folder: $dir"
        else
            mkdir -p "$dir"
            CREATED_DIRS+=("$dir")
            echo "Created folder: $dir"
        fi
    fi
}

# =========================================
# Process Files
# =========================================

process_files() {
    # Evaluate find command
    eval "$FIND_CMD" | while IFS= read -r file; do

        # Skip sorted_output directory
        if [[ "$file" =~ "$TARGET_DIR" ]]; then
            continue
        fi

        # Handle special characters in filenames
        file="$(printf '%q' "$file")"

        if [ -f "$file" ]; then
            # Get metadata date
            file_date="$(exiftool -s3 -DateTimeOriginal "$file" 2>/dev/null | awk -F'[: ]' '{print $1$2$3}')"

            # Fallback to other metadata fields
            if [ -z "$file_date" ]; then
                file_date="$(exiftool -s3 -CreateDate "$file" 2>/dev/null | awk -F'[: ]' '{print $1$2$3}')"
            fi

            if [ -z "$file_date" ]; then
                file_date="$(exiftool -s3 -ModifyDate "$file" 2>/dev/null | awk -F'[: ]' '{print $1$2$3}')"
            fi

            # Fallback to file modification date
            if [ -z "$file_date" ]; then
                file_date="$(date -r "$file" "+%Y%m%d")"
            fi

            # Normalize date
            if ! [[ "$file_date" =~ ^[0-9]{8}$ ]]; then
                file_date="UnknownDate"
            fi

            # Create target directory and move the file
            target_dir="$TARGET_DIR/$file_date"
            create_dir "$target_dir"
            move_file "$file" "$target_dir"
        fi
    done
}

# =========================================
# Process XMP Files
# =========================================

process_xmp() {
    find "$SOURCE_DIR" -type f -iname "*.xmp" | while IFS= read -r xmp_file; do
        corresponding_raw=""
        for ext in "${SUPPORTED_EXTENSIONS[@]}"; do
            if [ -f "${xmp_file%.xmp}.$ext" ]; then
                corresponding_raw="${xmp_file%.xmp}.$ext"
                break
            fi
        done

        if [ -n "$corresponding_raw" ]; then
            raw_dir="$(dirname "$corresponding_raw")"
            create_dir "$raw_dir"
            move_file "$xmp_file" "$raw_dir"
        else
            echo "Skipping $xmp_file because no corresponding RAW file found."
        fi
    done
}

# =========================================
# Remove Empty Folders
# =========================================

remove_empty_folders() {
    find "$SOURCE_DIR" -type d -empty | while IFS= read -r dir; do
        if [ "$dir" != "$TARGET_DIR" ]; then
            if [ "$DRYRUN" = true ]; then
                echo "[DRYRUN] Would remove empty folder: $dir"
            else
                rmdir "$dir"
                echo "Removed empty folder: $dir"
            fi
        fi
    done
}

# =========================================
# Run the Processes
# =========================================

process_files
process_xmp
remove_empty_folders

# Create the sorted flag file
if [ "$DRYRUN" = false ]; then
    touch "$SORTED_FLAG"
fi

echo "Sorting complete."
