# FanucPy Command-Line Tools

FanucPy provides several command-line tools for controlling your FANUC robot without writing Python code. These tools can be useful for quick testing, debugging, or demonstrating robot functionality.

## Installation

The command-line tools are installed automatically when you install the FanucPy package:

```bash
pip install -U fanucpy
```

## Available Tools

### Tool, User Frame, and Coordinate System Tool

The `cli_tool_user_coord.py` script provides commands for managing tool frames, user frames, and coordinate systems.

#### Setting Tool Frame

```bash
python cli_tool_user_coord.py --host 192.168.1.10 set_tool 3
```

This sets the active tool to tool number 3.

#### Setting User Frame

```bash
python cli_tool_user_coord.py --host 192.168.1.10 set_user 2
```

This sets the active user frame to user frame number 2.

#### Setting Coordinate System

```bash
python cli_tool_user_coord.py --host 192.168.1.10 set_coord TOOL
```

This sets the active coordinate system to TOOL coordinates. Valid options are:
- `WORLD`: World coordinate system
- `USER`: User frame coordinate system
- `TOOL`: Tool coordinate system

#### Getting Current Settings

```bash
python cli_tool_user_coord.py --host 192.168.1.10 get_tool
python cli_tool_user_coord.py --host 192.168.1.10 get_user
python cli_tool_user_coord.py --host 192.168.1.10 get_coord
```

These commands show the current tool number, user frame number, and coordinate system setting.

### Jogging Tool

The `cli_jog.py` script provides commands for continuous robot jogging (iPendant-like controls).

#### Starting Jogging

```bash
python cli_jog.py --host 192.168.1.10 start --axis X --dir + --speed 30
```

This starts jogging in the X+ direction at 30% speed. The parameters are:
- `axis`: One of X, Y, Z, W, P, R
- `dir`: Either + or -
- `speed`: Speed percentage (1-100, default is 25%)
- `step`: Step size per tick (optional, defaults to 0.25mm for XYZ, 0.5deg for WPR)

#### Stopping Jogging

```bash
# Stop jogging a specific axis
python cli_jog.py --host 192.168.1.10 stop --axis X

# Stop all jogging operations
python cli_jog.py --host 192.168.1.10 stop-all
```

## CLI Help

To see all available options for any command, use the `--help` flag:

```bash
python cli_tool_user_coord.py --help
python cli_jog.py --help
```

## Usage Notes

- The robot controller must be in remote mode
- No active alarms or faults should be present on the robot
- A network connection must be established to the robot's IP address
- The MAPPDK server must be running on the robot controller

## Security Considerations

The command-line tools provide direct control over robot movement. Always ensure:

1. The robot workspace is clear and safe
2. Personnel are aware of robot operation
3. Emergency stop systems are accessible
4. Commands are verified before execution