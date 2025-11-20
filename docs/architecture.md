# System Architecture Documentation

## Overview

The FanucPy system consists of two main components that communicate over a TCP/IP network connection:

1. **Robot Controller (fanuc_remote)**: KAREL and TP programs running on the FANUC robot controller
2. **Client Application (FanucPy)**: Python library running on an external computer

This architecture enables sophisticated robot control applications to run on external computers while controlling the physical robot through standard network protocols.

![Communication Protocol](../rpi/fanuc_package/media/CommProtocol.png)

## Robot Controller Component

For detailed technical documentation about the FANUC driver architecture, socket communication, and command processing pipeline, see [**Driver Architecture Documentation**](driver_architecture.md) and [**Command Reference**](command_reference.md).

### Core Server Components

The KAREL programs that make up the controller-side implementation:

| Component | Description |
|-----------|-------------|
| `fanuc_remote_server.kl` | Main server program that handles TCP connections and dispatches commands |
| `fanuc_remote_cmd.kl` | Command handler routines that implement the command processing logic |
| `fanuc_remote_comm.kl` | Communication utilities for opening/closing TCP connections |
| `fanuc_remote_context.kl` | Manages kinematic context (tool, user frame, coordinate system) |
| `fanuc_remote_jog.kl` | Implements continuous jogging functionality similar to iPendant |
| `fanuc_remote_utils.kl` | General utility functions used across the driver |
| `fanuc_remote_logger.kl` | Logging functionality for debugging and monitoring |

### Motion Execution Components

The TP programs that execute actual robot motion:

| Component | Description |
|-----------|-------------|
| `fanuc_remote_move.ls` | TP program for joint motion execution |
| `fanuc_remote_movel.ls` | TP program for linear motion execution |
| `SET_UTOOL_TP.ls` | TP program for setting the tool frame number |
| `SET_UFRAME_TP.ls` | TP program for setting the user frame number |
| `fanuc_remote.ls` | Main entry point TP program |

## Python Client Component

### Core Classes

| Class | Description |
|-------|-------------|
| `Robot` | Main class for robot control with methods for motion, I/O, and state queries |
| `RobotApp` | Abstract base class for building modular robot applications |

### Modules

| Module | Description |
|--------|-------------|
| `robot.py` | Core robot control functionality |
| `robotapp.py` | Application framework |
| `transformations.py` | Geometric transformations and math utilities |
| `calibration.py` | Robot calibration utilities |

### Command-Line Tools

| Tool | Description |
|------|-------------|
| `cli_tool_user_coord.py` | CLI for tool/user frame and coordinate system management |
| `cli_jog.py` | CLI for jogging operations |

## Communication Protocol

The client and server communicate using a simple text-based protocol over TCP/IP:

- **Connection**: TCP connection on port 18735 (default)
- **Command Format**: Text-based commands with parameters separated by colons or spaces
- **Response Format**: `<code>:<message>` where code is 0 for success, 1 for error
- **EOL Character**: Commands end with a newline character (`\n`)

### Command Categories

1. **Motion Commands**:
   - `movej`: Joint motion
   - `movep`: Cartesian motion

2. **Position Queries**:
   - `curpos`: Get current Cartesian position
   - `curjpos`: Get current joint position

3. **I/O Operations**:
   - `setdout`, `getdout`: Digital outputs
   - `setrdo`, `getrdo`: Robot digital outputs

4. **Frame Selection**:
   - `set_tool`, `get_tool`: Tool frame selection
   - `set_user`, `get_user`: User frame selection
   - `set_coord`, `get_coord`: Coordinate system selection

5. **Jogging Operations**:
   - `jog_start`: Start continuous jogging
   - `jog_stop`: Stop specific jogging axis
   - `jog_stop_all`: Stop all jogging operations

### Example Exchanges

Joint motion command and response:
```
CLIENT: movej:0100:0100:050:0:6:+000.000000000:-090.000000000:+000.000000000:+000.000000000:+000.000000000:+000.000000000
SERVER: 0:success
```

Position query command and response:
```
CLIENT: curpos
SERVER: 0:1470.260000:280.150000:695.390000:179.990000:0.000000:0.000000
```

## Data Flow

1. **Motion Execution**:
   - Python client constructs motion command
   - Command is sent to robot server
   - Server parses command and validates parameters
   - Server updates position register PR[81]
   - Server calls appropriate TP program (fanuc_remote_move.ls or fanuc_remote_movel.ls)
   - Server responds with success/error message

2. **Position Query**:
   - Python client sends query command
   - Server reads current position from robot
   - Server formats response and sends back to client
   - Client parses response into appropriate data structure

3. **Jogging Operation**:
   - Client sends jog_start command with parameters
   - Server activates the specified axis for jogging
   - Jog tick task applies small increments at regular intervals
   - Client sends jog_stop command when finished
   - Server deactivates the axis

## Register Usage

The system uses several FANUC registers for operation:

| Register | Purpose |
|----------|---------|
| `R[81]` | Motion velocity |
| `R[82]` | Motion acceleration |
| `R[83]` | CNT value for motion blending |
| `R[84]` | Tool number for SET_UTOOL_TP |
| `R[85]` | User frame number for SET_UFRAME_TP |
| `PR[81]` | Position register for motion execution |

## Deployment Architecture

The typical deployment architecture consists of:

1. **FANUC Robot Controller** (running fanuc_remote)
   - Connected to a local network via Ethernet
   - Running as TCP server on port 18735

2. **Control Computer** (running FanucPy)
   - Connected to the same local network
   - Running Python application that imports fanucpy
   - Connects to robot controller via IP address and port

This separation allows complex applications to run on a powerful external computer while the robot controller focuses on real-time motion control.