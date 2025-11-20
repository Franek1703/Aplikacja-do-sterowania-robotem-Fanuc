# FanucPy - Python Interface for FANUC Robots

## Overview

FanucPy is a comprehensive solution for controlling FANUC robots from Python applications. It consists of a KAREL/TP server that runs on the robot controller and a Python library that provides a high-level API for robot control. This architecture enables the development of sophisticated robot applications that can run on external computers while controlling the physical robot through a standard network connection.

The library provides advanced robot control capabilities including:

- **Motion Control**: Both joint-space and Cartesian-space movements
- **Coordinate Frame Management**: Full control over tool frames, user frames, and coordinate systems
- **iPendant-like Jogging**: Intuitive continuous motion control in all 6 degrees of freedom
- **Application Framework**: Modular, plug-and-produce approach to robot applications
- **Command Line Tools**: CLI utilities for rapid testing and demonstrations

> **Note**: This project is an extension of the original work by Agajan Torayev.

## Software Contents
The package consists of two parts: 
1. Robot interface code written in Python programming language
2. FANUC robot controller driver (tested with R-30iB Mate Plus Controller) written in KAREL and FANUC teach pendant languages

The communication protocol between the Python package and the FANUC robot controller is depicted below:
![Communication Protocol](media/CommProtocol.png)

## Features

- **Robot Motion Control**: Joint and Cartesian space movements
- **Tool Management**: Set and get tool frames (UTOOL)
- **User Frame Management**: Set and get user frames (UFRAME)
- **Coordinate System Selection**: WORLD, USER, TOOL coordinate systems
- **Jogging Operations**: iPendant-like continuous jogging in all 6 axes
- **I/O Control**: Digital inputs and outputs, robot I/O
- **Position Queries**: Get current position in joint or Cartesian space
- **Application Framework**: RobotApp class for building robot applications
- **Command Line Tools**: CLI tools for tool/user frames and jogging

## Repository Structure

```
.
├── README.md                      # This file
├── docs/                          # Documentation
│   ├── index.md                   # Documentation index
│   ├── cli_tools.md               # Command-line tools documentation
│   ├── frames_and_coords.md       # Tool/user frame documentation
│   └── jogging.md                 # Jogging functionality documentation
├── fanuc-driver/                  # KAREL/TP driver for FANUC controller
│   ├── fanuc_remote_server.kl     # Main server program
│   ├── fanuc_remote_cmd.kl        # Command handlers
│   ├── fanuc_remote_jog.kl        # Jogging functionality
│   └── ... (other KAREL/TP files)
├── rpi/                           # Raspberry Pi components
│   └── fanuc_package/             # Python package
│       ├── src/                   # Source code
│       │   └── robot/             # Robot control library
│       │       ├── robot.py       # Core Robot class
│       │       └── robotapp.py    # Application framework
│       ├── examples/              # Example applications
│       │   ├── PickAndPlaceApp.py # Pick and place example
│       │   ├── ArucoTrackingApp.py# Vision-based tracking example
│       │   ├── fanucpy-gpt/       # GPT-assisted examples
│       │   └── voice-commands/    # Voice control examples
│       ├── cli_tool_user_coord.py # CLI for tool/user frames
│       └── cli_jog.py             # CLI for jogging operations
```

## Python Package Installation
```bash
pip install -U fanucpy
```

## Driver Installation
Follow these [steps](fanuc.md) to install the FANUC driver.

## Usage
### Connect to a robot:
```python
from fanucpy import Robot

robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735,
    ee_DO_type="RDO",
    ee_DO_num=7,
)

robot.connect()
```

### Moving
```python
# move in joint space
robot.move(
    "joint",
    vals=[19.0, 66.0, -33.0, 18.0, -30.0, -33.0],
    velocity=100,
    acceleration=100,
    cnt_val=0,
    linear=False
)

# move in cartesian space
robot.move(
    "pose",
    vals=[0.0, -28.0, -35.0, 0.0, -55.0, 0.0],
    velocity=50,
    acceleration=50,
    cnt_val=0,
    linear=False
)
```

### Opening/closing gripper
```Python
# open gripper
robot.gripper(True)

# close gripper
robot.gripper(False)
```

### Querying robot state
```python
# get robot state
print(f"Current pose: {robot.get_curpos()}")
print(f"Current joints: {robot.get_curjpos()}")
print(f"Instantaneous power: {robot.get_ins_power()}")
print(f"Get gripper state: {robot.get_rdo(7)}")
```

### Calling external program
```python
robot.call_prog(prog_name)
```

### Tool, User Frame, and Coordinate System
```python
# Set tool frame #3
robot.set_tool(3)

# Set user frame #2
robot.set_user(2)

# Set coordinate system to TOOL
robot.set_coord("TOOL")

# Get current settings
code, tool_num = robot.get_tool()
code, user_num = robot.get_user()
code, coord_type = robot.get_coord()

print(f"Current settings: Tool={tool_num}, User={user_num}, Coord={coord_type}")
```

### Jogging Operations (iPendant-like)
```python
# Start jogging X+ at 30% speed (continuous motion)
robot.jog_start("X", "+", speed=30)

# Wait for 2 seconds (simulating button press)
import time
time.sleep(2)

# Stop jogging (button release)
robot.jog_stop("X")

# Start jogging multiple axes
robot.jog_start("Y", "+", speed=20)
robot.jog_start("Z", "-", speed=15)

# Stop all jogging operations
robot.jog_stop_all()
```

### Get/Set RDO
```python
robot.get_rdo(rdo_num=7)
robot.set_rdo(rdo_num=7, value=True)
```

### Get/Set DOUT
```python
robot.get_rdo(dout_num=1)
robot.set_rdo(dout_num=1, value=True)
```

## Contributions
External contributions are welcome!

- Agajan Torayev: Key developer
- Karol
- Fan Mo
- Michael Yiu: External contributor


## Command Line Tools

### Tool/User Frame and Coordinate System Tool

```bash
# Set tool number
python cli_tool_user_coord.py --host 192.168.1.10 set_tool 3

# Set user frame number
python cli_tool_user_coord.py --host 192.168.1.10 set_user 2

# Set coordinate system
python cli_tool_user_coord.py --host 192.168.1.10 set_coord TOOL

# Get current settings
python cli_tool_user_coord.py --host 192.168.1.10 get_tool
python cli_tool_user_coord.py --host 192.168.1.10 get_user
python cli_tool_user_coord.py --host 192.168.1.10 get_coord
```

### Jogging Tool

```bash
# Start jogging X+ at default speed
python cli_jog.py --host 192.168.1.10 start --axis X --dir +

# Start jogging Z- at 50% speed with custom step size
python cli_jog.py --host 192.168.1.10 start --axis Z --dir - --speed 50 --step 0.5

# Stop jogging a specific axis
python cli_jog.py --host 192.168.1.10 stop --axis X

# Stop all jogging
python cli_jog.py --host 192.168.1.10 stop-all
```

## Documentation

### Python Library Documentation

- [**FanucPy Documentation Index**](docs/index.md): Complete Python package documentation
- [**Python API Reference**](docs/python_api_reference.md): Complete API for all Robot class methods
- [**Connection Guide**](docs/connection_guide.md): Step-by-step connection setup and troubleshooting
- [**FTP Access**](docs/ftp_access.md): Program file access via FTP
- [**Extended FTP**](docs/extended_ftp.md): Advanced FTP operations

### System Documentation

- [**Complete Documentation Index**](../../docs/index.md): Main documentation hub
- [**System Architecture**](../../docs/architecture.md): Overall system design and communication flow
- [**Driver Architecture**](../../docs/driver_architecture.md): Detailed FANUC driver technical documentation
- [**Command Reference**](../../docs/command_reference.md): TCP/IP command reference with examples

### Feature Documentation

- [**Tool, User Frame, and Coordinate System**](../../docs/frames_and_coords.md): Coordinate frame management
- [**Jogging Functionality**](../../docs/jogging.md): iPendant-like continuous motion control
- [**Command-Line Tools**](../../docs/cli_tools.md): CLI utilities documentation

### Component Documentation

- [**KAREL/TP Driver**](../../fanuc-driver/README.md): Robot controller side implementation

## RobotApp
The `RobotApp` class facilitates modularity and plug-and-produce functionality. Check the following example apps:

1. [Pick and Place App](examples/PickAndPlaceApp.py)
2. [Aruco Tracking App](examples/ArucoTrackingApp.py)
3. [FANUC ChatGPT](examples/fanucpy-gpt/README.MD)

## Contributions
External contributions are welcome!

- Agajan Torayev: Original developer
- Karol
- Fan Mo
- Michael Yiu: External contributor

## Citation
If you are using this library in academic publications, please cite [Towards Modular and Plug-and-Produce Manufacturing Apps](https://www.sciencedirect.com/science/article/pii/S2212827122004255)

```
@article{torayev2022towards,
  title={Towards Modular and Plug-and-Produce Manufacturing Apps},
  author={Torayev, Agajan and Mart{\'\i}nez-Arellano, Giovanna and Chaplin, Jack C and Sanderson, David and Ratchev, Svetan},
  journal={Procedia CIRP},
  volume={107},
  pages={1257--1262},
  year={2022},
  publisher={Elsevier}
}
```

## Acknowledgements
This work was originally developed at the [Institute for Advanced Manufacturing at the University of Nottingham](https://www.nottingham.ac.uk/ifam/index.aspx) as a part of the [Digital Manufacturing and Design Training Network](https://dimanditn.eu/).

This project has received funding from the European Union’s Horizon 2020 research and innovation programme under the Marie Skłodowska-Curie grant agreement No 814078.
