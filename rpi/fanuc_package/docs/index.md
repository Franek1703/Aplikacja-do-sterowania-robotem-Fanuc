# FanucPy Documentation

## Overview

FanucPy is a Python package that provides an interface for controlling and communicating with FANUC robots. It abstracts the underlying communication protocol and provides a user-friendly API for robot control, automation, and integration.

The package uses two communication protocols:
- **TCP Socket (Port 18735)**: Real-time robot control, motion, I/O, and queries
- **FTP (Port 21)**: File system access for program listing and reading

## Features

- TCP/IP communication with FANUC controllers
- Motion control (joint and Cartesian space)
- Jogging operations (iPendant-like continuous motion)
- Tool/User frame and coordinate system management
- I/O operations (RDO, DOUT)
- Program execution
- FTP file access for program management
- Application framework (RobotApp)
- Command-line tools

## Quick Start

```python
from fanucpy import Robot

# Create robot instance
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735
)

# Connect via TCP socket
robot.connect()

# Get current position
position = robot.get_curpos()
print(f"Position: {position}")

# Move robot
robot.move("joint", vals=[0, -90, 0, 0, 0, 0], velocity=50)

# Disconnect
robot.disconnect()
```

## Documentation

### Getting Started

- [**Connection Guide**](connection_guide.md) - Complete guide to connecting to FANUC robots, network setup, and troubleshooting
- [**Python API Reference**](python_api_reference.md) - Complete API documentation for all available methods and protocols
- [**Socket vs FTP Communication**](socket_vs_ftp.md) - Quick reference comparing TCP Socket and FTP protocols

### Features

- [**Jogging**](jogging.md) - Guide to robot jogging operations
- [**Frames and Coordinates**](frames_and_coords.md) - Working with tool and user frames
- [**FTP Access**](ftp_access.md) - Working with robot program files
- [**Extended FTP**](extended_ftp.md) - Advanced FTP operations (read, write, directory management)

### Tools

- [**CLI Tools**](cli_tools.md) - Command-line interface tools for robot control

## Additional Resources

For system architecture and driver documentation:
- [System Architecture](../../../docs/architecture.md)
- [Driver Architecture](../../../docs/driver_architecture.md)
- [Command Reference](../../../docs/command_reference.md)