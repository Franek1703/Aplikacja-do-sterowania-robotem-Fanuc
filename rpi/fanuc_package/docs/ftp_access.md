# FTP File Access

The FanucPy package provides FTP capabilities to access, list, and read program files directly from the robot controller.

## Overview

The FTP functionality is implemented in the `ftp.py` module and is integrated into the main `Robot` class. This allows users to:

1. List program files on the robot's memory devices
2. Read program contents
3. Filter programs by type (TP, KAREL) or pattern

## Core Functionality

### Listing Programs

```python
robot.list_programs(device="MD", pattern="*", types="ALL")
```

- **device**: Specifies the device to list files from (e.g., "MD" for memory card, "UD1" for user device)
- **pattern**: Filter files by name pattern with wildcard support (e.g., "PICK_*.TP")
- **types**: Filter files by type ("TP", "KAREL", or "ALL")

### Reading Program Files

```python
content = robot.read_program("MD", "PROGRAM.TP")
```

This retrieves the full content of the specified program as a string.

## Supported Devices

Common devices on FANUC robots include:

- **MD**: Memory card
- **UD1**, **UD2**: User devices (USB drives)
- **FR**: FROM memory
- **MO**: Memory option

## Supported File Types

The FTP module can handle various file types found on FANUC controllers:

- **TP programs** (.TP, .LS): Teach Pendant programs
- **KAREL programs** (.KL): KAREL language programs
- **Program control files** (.PC): Program control files

## Error Handling

The FTP module provides comprehensive error handling for common FTP issues:

- Connection failures
- Authentication errors
- File not found errors
- Permission issues

All errors are wrapped in `FanucError` exceptions with descriptive messages.

## Example Usage

```python
from robot import Robot

# Initialize robot with FTP credentials if needed
robot = Robot(
    robot_model="Fanuc",
    host="192.168.56.8",
    ftp_user="anonymous",
    ftp_password=""
)

# Connect to the robot
robot.connect()

# List all TP programs
tp_programs = robot.list_programs(device="MD", types="TP")
print(f"Found {len(tp_programs)} TP programs:")
for prog in tp_programs:
    print(f" - {prog}")

# Read a specific program
if tp_programs:
    program_name = tp_programs[0]
    content = robot.read_program("MD", program_name)
    print(f"\nContents of {program_name}:")
    print(content[:200] + "..." if len(content) > 200 else content)

# Disconnect
robot.disconnect()
```