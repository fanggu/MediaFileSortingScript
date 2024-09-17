# Photo and Video Sorting Script

## Overview

This Bash script automatically organizes photos and videos by their shooting date (from EXIF data) or file creation date (if EXIF data is not available). It sorts files into directories based on the year, month, and optionally the day the media was captured. The script is useful for managing large collections of media files from various devices and platforms.

## Features

- **EXIF Metadata Sorting**: Prioritizes sorting based on the shooting date from EXIF data for supported file types.
- **Fallback to File Creation Date**: Uses the file's creation or modification date if no EXIF data is available.
- **Directory Structure**: Files are sorted into subdirectories by year, month, and day.
- **Supported File Types**: Handles common image and video formats, including JPEG, PNG, RAW (e.g., CR2, NEF), MOV, MP4, and more.
- **Logging**: The script logs processed files for future reference.
- **Dry Run Option**: Allows users to simulate the sorting process without making actual changes.

## Usage

```bash
./sort_media.sh [-dryrun|--dryrun] [-force|--force] /path/to/source/directory
