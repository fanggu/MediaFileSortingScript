# Photo and Video Sorting Script

## Overview

This Bash script automates the sorting of photos and videos into folders based on their shooting date (from EXIF metadata) or file modification date if no EXIF data is available. It offers options for dry runs, restoring files, and excluding directories. The script supports a wide range of image and video file formats and includes the ability to handle additional extensions.

## Features

- **EXIF Metadata Sorting**: Sorts files based on their shooting date stored in EXIF metadata.
- **Fallback to File Modification Date**: Uses the file's modification date if no EXIF data is available.
- **Customizable File Extensions**: You can specify additional file extensions for sorting.
- **Dry Run Option**: Preview sorting operations without making any changes.
- **Force Restore**: Restores previously sorted files to their original locations.
- **Directory Exclusion**: Optionally exclude directories from being processed.
- **Support for Various Media Formats**: Works with popular photo and video formats (e.g., JPEG, PNG, RAW, MOV, MP4).

## Usage

```bash
./script.sh [options] /path/to/source/photos
```

### Options

- `--dryrun` - Simulate the sorting process without making changes.
- `--force` - Force resorting of files that have already been sorted.
- `--restore` - Restore files to their original locations.
- `--extensions ext1,ext2` - Specify additional file extensions to include in the sorting process.
- `--exclude-dirs dir1,dir2` - Exclude specific directories from being processed.
- `--no-prompt` - Do not prompt for confirmations.

### Example

```bash
./script.sh --dryrun --exclude-dirs "backup,temp" /path/to/source/photos
```

This example simulates sorting photos while excluding `backup` and `temp` directories.

### File Restoration

To restore previously sorted files:

```bash
./script.sh --restore /path/to/source/photos
```

This restores all files based on the log file and deletes the sorted directory, flag, and log file.

## Supported File Formats

The script supports the following file types by default:

- **Image Formats**: JPG, JPEG, PNG, CR2, CR3, NEF, ARW, RW2, ORF, RAF, DNG.
- **Video Formats**: MOV, MP4, AVI, MKV, WMV, FLV, MPEG, MPG.

You can extend this list using the `--extensions` option.

## Requirements

- **bash** (standard shell environment)
- **exiftool** (required to read EXIF metadata)

### Installing `exiftool`

On Linux (Debian-based systems):

```bash
sudo apt-get install exiftool
```

On macOS (using Homebrew):

```bash
brew install exiftool
```

## Directory Structure

The script organizes files into the following folder structure:

```
/sorted_output/
  ├── 20240909
  │   └── IMG_1234.JPG
  │   └── VIDEO_5678.MP4
  └── ... (more files)
```

## Logging

The script logs all processed files to `sorted_files.log`. You can use this log to restore files to their original locations if necessary.

## License

This project is licensed under the GPL-3.0 license - see the [LICENSE](LICENSE) file for details.