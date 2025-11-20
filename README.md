# Fanuc Robot Control Application

This repository contains a comprehensive solution for controlling FANUC robots from Python applications. It consists of two main components:

1. **fanuc-driver**: KAREL and TP programs that implement the robot controller driver for FANUC robots. These programs run on the FANUC controller and provide a TCP/IP-based interface for control operations.

2. **rpi/fanuc_package**: A Python library that communicates with the FANUC controller to provide a high-level API for robot control.

## Repository Structure

```
.
├── README.md                      # This file
├── docs/                          # Documentation
│   ├── index.md                   # Documentation index
│   ├── cli_tools.md               # Command-line tools documentation
│   ├── frames_and_coords.md       # Tool/user frame documentation
│   └── jogging.md                 # Jogging functionality documentation
├── app/                           # Main application
├── fanuc-driver/                  # KAREL/TP driver for FANUC controller
│   ├── fanuc_remote_server.kl     # Main server program
│   ├── fanuc_remote_cmd.kl        # Command handlers
│   └── ...                        # Other driver files
└── rpi/                           # Raspberry Pi components
    └── fanuc_package/             # Python package for robot control
        ├── src/                   # Source code
        │   └── robot/             # Robot control library
        ├── examples/              # Example applications
        └── docs/                  # Python package documentation
```

## Getting Started

### 1. Install the FANUC Driver

See the [fanuc-driver/README.md](fanuc-driver/README.md) file for detailed instructions on installing the FANUC driver on the robot controller.

### 2. Install the Python Package

```bash
cd rpi/fanuc_package
pip install -e .
```

### 3. Run an Example

```bash
python rpi/fanuc_package/examples/demo.py
```

## Documentation

For complete documentation, see the [docs/index.md](docs/index.md) file.