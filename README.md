# Photo and Video Sorting Script

**Version:** 1.2.1

---

## Overview

This script organizes your photos and videos into date-based folders by extracting the creation date from each file's metadata. It's designed to handle a wide range of file types and supports custom date formats for folder naming.

---

## Features

- **Multiple File Formats**: Supports various photo and video file formats, including RAW images and modern formats like HEIC/HEIF.
- **Metadata Extraction**: Extracts dates from metadata fields like `DateTimeOriginal`, `CreateDate`, and `ModifyDate`.
- **Custom Date Formats**: Allows custom date formats for folder names using the `--date-format` option.
- **Dry Run Mode**: Simulate actions without making any changes using the `--dryrun` option.
- **Restoration Capability**: Can restore files to their original locations with the `--restore` option.
- **Exclusion of Directories**: Exclude specified directories from processing using the `--exclude-dirs` option.
- **Special Character Handling**: Handles files with spaces and special characters in filenames.
- **Conflict Resolution**: Implements a counter mechanism to prevent overwriting files with the same name.
- **Cross-Platform Compatibility**: Designed to work on both GNU/Linux and macOS systems.

---

## Requirements

- **Bash Shell**: The script is written for the Bash shell.
- **exiftool**: Used for extracting metadata from files.
  - **Installation**:
    - **Ubuntu/Debian**: `sudo apt-get install exiftool`
    - **macOS (Homebrew)**: `brew install exiftool`
    - **Windows**: Available via [exiftool website](https://exiftool.org/)

---

## Usage

```bash
./script.sh [options] /path/to/source/photos
```

### Options

- `--dryrun`  
  Simulate actions without making changes.

- `--force`  
  Restore files before sorting again.

- `--restore`  
  Restore files to original locations.

- `--help`  
  Display the help message.

- `--extensions ext1,ext2`  
  Specify additional file extensions to include.

- `--exclude-dirs dir1,dir2`  
  Exclude specified directories from processing.

- `--date-format format`  
  Specify date format for folder names (e.g., `%Y-%m-%d`).

- `--no-prompt`  
  Do not prompt for confirmations.

### Date Format Specifiers

- `%Y` - Year (e.g., `2023`)
- `%m` - Month as a number (`01`-`12`)
- `%B` - Full month name (e.g., `July`)
- `%b` - Abbreviated month name (e.g., `Jul`)
- `%d` - Day of the month (`01`-`31`)
- `%H` - Hour (`00`-`23`)
- `%M` - Minute (`00`-`59`)
- `%S` - Second (`00`-`59`)

---

## Examples

### Default Date Format (`%Y%m%d`)

```bash
./script.sh /path/to/source/photos
```

- **Folder Names**: `sorted_output/20230715`

### Custom Date Format with Hyphens (`%Y-%m-%d`)

```bash
./script.sh --date-format "%Y-%m-%d" /path/to/source/photos
```

- **Folder Names**: `sorted_output/2023-07-15`

### Nested Folder Structure (`%Y/%m/%d`)

```bash
./script.sh --date-format "%Y/%m/%d" /path/to/source/photos
```

- **Folder Hierarchy**:
  - `sorted_output/2023/07/15`

### Including Time in Folder Names (`%Y-%m-%d_%H-%M-%S`)

```bash
./script.sh --date-format "%Y-%m-%d_%H-%M-%S" /path/to/source/photos
```

- **Folder Names**: `sorted_output/2023-07-15_14-30-00`

### Using Month Names (`%B_%Y`)

```bash
./script.sh --date-format "%B_%Y" /path/to/source/photos
```

- **Folder Names**: `sorted_output/July_2023`

### Dry Run with Custom Date Format

```bash
./script.sh --dryrun --date-format "%Y-%m-%d" /path/to/source/photos
```

### Specifying Additional Extensions

```bash
./script.sh --extensions heic,heif /path/to/source/photos
```

### Excluding Directories

```bash
./script.sh --exclude-dirs tmp,backup /path/to/source/photos
```

### Restoring Files

```bash
./script.sh --restore /path/to/source/photos
```

---

## Important Notes

### Dependencies

- **exiftool** must be installed for the script to function correctly.
- The script relies on system commands like `find`, `date`, `mv`, and `mkdir`.

### Cross-Platform Compatibility

- The script is compatible with both GNU/Linux and macOS systems.
- Differences in the `date` command between systems are handled within the script.

### Handling Special Characters in Filenames

- The script is designed to handle filenames with spaces and special characters.
- Ensure that your shell environment supports these filenames.

### Error Handling

- The script validates the date format provided by the user.
- If an invalid date format is detected, the script will display an error and exit.
- It's recommended to use the `--dryrun` option first to preview actions.

### Backup and Safety

- Always backup your data before running scripts that modify or move files.
- The script includes a `--force` option to restore files before sorting again.
- The `--restore` option can be used to restore files to their original locations.

### Date Format Validation

- The script attempts to validate the date format before processing.
- It uses a known test date to ensure the format is acceptable.
- On systems where the date command behaves differently, validation may fail. In such cases, adjust the date format accordingly.

---

## Changelog

### Version 1.2.1

- **Custom Date Format**: Added the ability for users to set a custom date format for folder names using the `--date-format` option.
- **Date Format Validation**: Improved date format validation to handle both GNU and BSD variants of the `date` command.
- **Error Messages**: Enhanced error messages and feedback to the user for better clarity.
- **Supported Extensions**: Expanded the list of supported file extensions to include modern formats like `heic` and `heif`.
- **Bug Fixes**: Fixed issues with date format validation on macOS systems.

---

## License

This script is released under the GPL-3.0 License.

---

## Acknowledgments

- **exiftool** by Phil Harvey for metadata extraction.


---

## Support

If you encounter any issues or have suggestions for improvements, feel free to reach out or open an issue in the project's repository.

---

## Disclaimer

Use this script at your own risk. The author is not responsible for any loss of data or damage caused by using this script. Always ensure you have backups of your data before running scripts that modify files.

---
d-.-b