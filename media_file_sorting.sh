#!/bin/bash

# Initialization of variables
DRYRUN=false
FORCE=false
LOG_FILE=""
SORTED_FLAG=""
FORCE_RESORT_TEMP_FOLDER=""

# Parse command line arguments
while [[ "$1" =~ ^- ]]; do
  case "$1" in
    -dryrun|--dryrun)
      DRYRUN=true
      ;;
    -force|--force)
      FORCE=true
      ;;
  esac
  shift
done

# Get the source directory
SOURCE_DIR="$1"

# Check if the source directory is provided
if [ -z "$SOURCE_DIR" ]; then
  echo "Usage: $0 [-dryrun|--dryrun] [-force|--force] /path/to/source/photos"
  exit 1
fi

# Set target directory and flag paths
TARGET_DIR="$SOURCE_DIR/sorted_output"
LOG_FILE="$TARGET_DIR/sorted_files.log"
SORTED_FLAG="$TARGET_DIR/.sorted_done"
FORCE_RESORT_TEMP_FOLDER="$SOURCE_DIR/force_resort_temp"

# If --force is present, rename sorted_output to force_resort_temp and continue
if [ "$FORCE" = true ]; then
  if [ -d "$TARGET_DIR" ]; then
    if [ "$DRYRUN" = true ]; then
      echo "[DRYRUN] Would rename $TARGET_DIR to $FORCE_RESORT_TEMP_FOLDER"
    else
      mv "$TARGET_DIR" "$FORCE_RESORT_TEMP_FOLDER"
      echo "Renamed $TARGET_DIR to $FORCE_RESORT_TEMP_FOLDER for forced resort."
    fi
  fi
else
  # If --force is not present, check if sorting has already been done
  if [ -f "$SORTED_FLAG" ]; then
    echo "This folder has already been sorted. Use --force to sort again."
    exit 1
  fi
fi

# Create target directory if it doesn't exist (after renaming)
if [ "$DRYRUN" = true ]; then
  echo "[DRYRUN] Would create target directory: $TARGET_DIR"
else
  mkdir -p "$TARGET_DIR"
  echo "Created target directory: $TARGET_DIR"
fi

# Initialize the log file
if [ "$DRYRUN" = false ]; then
  touch "$LOG_FILE"
fi

processed_files=()
created_dirs=()

# Load already processed files from the log
if [ -f "$LOG_FILE" ]; then
  while IFS= read -r file; do
    processed_files+=("$file")
  done < "$LOG_FILE"
fi

# Function to check if a file is already processed
is_processed() {
  local file="$1"
  for processed in "${processed_files[@]}"; do
    if [[ "$processed" == "$file" ]]; then
      return 0
    fi
  done
  return 1
}

# Function to move files
move_file() {
  local file="$1"
  local target_dir="$2"

  base_name=$(basename "$file")
  target_file="$target_dir/$base_name"

  # If --force and --dryrun are both true, skip counter logic
  if [ "$FORCE" = true ] && [ "$DRYRUN" = true ]; then
    echo "[DRYRUN] Would move file: $file to $target_file"
  else
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
      mv "$file" "$target_file"
      echo "Moved $file to $target_file"
      echo "$file" >> "$LOG_FILE"
    fi
  fi
}

# Function to ensure the target directory is created
create_dir() {
  local dir="$1"
  if [[ ! " ${created_dirs[@]} " =~ " $dir " ]]; then
    if [ "$DRYRUN" = true ]; then
      echo "[DRYRUN] Would create folder: $dir"
    else
      mkdir -p "$dir"
      created_dirs+=("$dir")
      echo "Created folder: $dir"
    fi
  fi
}

# Process files (JPEG, PNG, RAW formats, MOV, MP4, etc.)
process_files() {
  find "$SOURCE_DIR" -type f \( \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.cr2" -o -iname "*.cr3" \
    -o -iname "*.nef" -o -iname "*.arw" -o -iname "*.rw2" -o -iname "*.orf" -o -iname "*.raf" -o -iname "*.dng" \
    -o -iname "*.mov" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.wmv" -o -iname "*.flv" \
    -o -iname "*.mpeg" -o -iname "*.mpg" \) | while read -r file; do

    # Skip sorted_output folder unless --force is present
    if [[ "$FORCE" = false && "$file" =~ sorted_output ]]; then
      continue
    fi

    # Check if file has been processed or --force is used
    if ! is_processed "$file" || [ "$FORCE" = true ]; then
      if [ -f "$file" ]; then
        # Get the modification date if no metadata date
        file_date=$(exiftool -d "%Y%m%d" -DateTimeOriginal -T "$file" 2>/dev/null || date -r "$file" "+%Y%m%d")

        # Create target directory and move the file
        target_dir="$TARGET_DIR/$file_date"
        create_dir "$target_dir"
        move_file "$file" "$target_dir"
      fi
    fi
  done
}

# Process XMP files
process_xmp() {
  find "$SOURCE_DIR" -type f -iname "*.xmp" | while read -r xmp_file; do
    corresponding_raw=""
    for ext in cr2 cr3 nef arw rw2 orf raf dng; do
      if [ -f "${xmp_file%.xmp}.$ext" ]; then
        corresponding_raw="${xmp_file%.xmp}.$ext"
        break
      fi
    done

    if [ -n "$corresponding_raw" ]; then
      raw_dir=$(dirname "$corresponding_raw")
      create_dir "$raw_dir"
      move_file "$xmp_file" "$raw_dir"
    else
      echo "Skipping $xmp_file because no corresponding RAW file found."
    fi
  done
}

# Function to check and remove empty folders
remove_empty_folders() {
  local folder="$1"
  if [ -d "$folder" ] && [ -z "$(find "$folder" -type f)" ]; then
    if [ "$DRYRUN" = true ]; then
      echo "[DRYRUN] Would remove empty folder: $folder"
    else
      rm -rf "$folder"
      echo "Removed empty folder: $folder"
    fi
  fi
}

# Run the processes
process_files
process_xmp

# Check and remove empty force_resort_temp folder (and subfolders) if present
remove_empty_folders "$SOURCE_DIR"

# Remove the flags and log files in force_resort_temp if no files left
if [ "$DRYRUN" = false ]; then
  if [ -z "$(find "$FORCE_RESORT_TEMP_FOLDER" -type f)" ]; then
    [ -f "$FORCE_RESORT_TEMP_FOLDER/.sorted_done" ] && rm -f "$FORCE_RESORT_TEMP_FOLDER/.sorted_done"
    [ -f "$FORCE_RESORT_TEMP_FOLDER/sorted_files.log" ] && rm -f "$FORCE_RESORT_TEMP_FOLDER/sorted_files.log"
    remove_empty_folders "$FORCE_RESORT_TEMP_FOLDER"
    echo "Removed sorted flags and log file in $FORCE_RESORT_TEMP_FOLDER."
  fi
fi

echo "Sorting complete."