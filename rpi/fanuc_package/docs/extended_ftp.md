# Extended FTP Functionality

The FanucPy package now includes enhanced FTP capabilities for file and directory management on the robot controller.

## Overview

The extended FTP functionality in the `ftp.py` module provides comprehensive file system operations including:

1. Listing files and directories
2. Reading file contents
3. Writing new files
4. Creating and removing directories
5. Renaming files
6. Downloading files to the local system

## Core Functionality

### File Operations

```python
# Read a file
content = ftp.read_file("MD:", "PROGRAM.TP")

# Write a text file (good for TP programs)
ftp.write_text_file("MD:", "NEWPROG.TP", program_content)

# Write a binary file
ftp.write_file("MD:", "DATA.BIN", binary_data)

# Rename a file
ftp.rename_file("OLD_NAME.TP", "NEW_NAME.TP")

# Remove a file
ftp.remove_file("PROGRAM.TP")

# Download a file to local system
ftp.download_binary_file("MD:/PROGRAM.TP", "C:/local/path/program.tp")

# Get file size
size = ftp.get_file_size("PROGRAM.TP")
```

### Directory Operations

```python
# Get current directory
pwd = ftp.get_pwd()

# Change directory
ftp.change_directory("MD:/PROGRAMS")

# Create a new directory
ftp.create_directory("NEW_DIR")

# Remove a directory
ftp.remove_directory("OLD_DIR")
```

## Direct FTP Client Usage

While the `Robot` class integrates basic FTP functionality, you can also use the `RobotFTP` class directly for more advanced operations:

```python
from robot.ftp import RobotFTP

# Initialize and connect
ftp = RobotFTP(host="192.168.1.1", user="username", password="password")
ftp.connect()

# Use as a context manager
with RobotFTP(host="192.168.1.1") as ftp:
    files = ftp.list_files("MD:", "*", "TP")
    for file in files:
        print(file)
```

## Examples

### Creating and Uploading a TP Program

```python
from robot.ftp import RobotFTP

# TP program content
tp_program = """
/PROG  EXAMPLE
/ATTR
OWNER       = MNEDITOR;
COMMENT     = "Example program";
/MN
   1:  ! This is an example program ;
   2:  J P[1] 100% FINE ;
   3:  L P[2] 500mm/sec FINE ;
/POS
/END
"""

# Connect and upload
with RobotFTP(host="192.168.1.1") as ftp:
    ftp.write_text_file("MD:", "EXAMPLE.TP", tp_program)
```

### Recursive Directory Listing

```python
def list_recursive(ftp, path=""):
    """List all files recursively."""
    files = []
    
    # Get files in current directory
    current_files = ftp.list_files(path, "*", "ALL")
    for file in current_files:
        files.append(f"{path}/{file}" if path else file)
    
    # Try to find directories (this is a simplified approach)
    try:
        # Save current directory
        original_dir = ftp.get_pwd()
        
        # Change to the target path if specified
        if path:
            ftp.change_directory(path)
            
        # List entries
        entries = []
        ftp.ftp.dir(entries.append)
        
        # Look for directories
        for entry in entries:
            if entry.startswith('d'):  # Directory entries usually start with 'd'
                parts = entry.split()
                if len(parts) >= 9:
                    dir_name = parts[8]
                    # Skip "." and ".." directories
                    if dir_name not in (".", ".."):
                        # Recursively list the subdirectory
                        sub_path = f"{path}/{dir_name}" if path else dir_name
                        files.extend(list_recursive(ftp, sub_path))
        
        # Restore original directory
        ftp.change_directory(original_dir)
            
    except Exception:
        # Some FTP servers might not support directory operations as expected
        pass
    
    return files
```

## Error Handling

All FTP operations are wrapped with proper error handling and will raise `RobotFTPError` exceptions with descriptive messages when operations fail:

```python
from robot.ftp import RobotFTP, RobotFTPError

try:
    with RobotFTP(host="192.168.1.1") as ftp:
        ftp.write_text_file("MD:", "PROGRAM.TP", content)
except RobotFTPError as e:
    print(f"FTP operation failed: {e}")
```

## Supported File Types

The FTP module can handle various file types found on FANUC controllers:

- **TP programs** (.TP, .LS): Teach Pendant programs
- **KAREL programs** (.KL): KAREL language programs
- **Program control files** (.PC): Program control files
- **Binary files**: For other data transfer needs