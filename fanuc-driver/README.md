# FANUC Driver Documentation

## Overview

This folder contains the KAREL and LS program files that implement the fanuc_remote driver for FANUC robots. The driver enables external applications to communicate with and control FANUC robots through a TCP/IP connection, providing a high-level interface for robot control operations.

## Communication Protocol

fanuc_remote uses a simple text-based protocol over TCP/IP with the following characteristics:

- **Connection**: TCP connection on port 18735 (default)
- **Command Format**: Text-based commands with parameters separated by colons or spaces
- **Response Format**: `<code>:<message>` where code is 0 for success, 1 for error
- **EOL Character**: Commands end with a newline character (`\n`)

### Example Command-Response Flow:

```
CLIENT: movej:0100:0100:050:0:6:+000.000000000:-090.000000000:+000.000000000:+000.000000000:+000.000000000:+000.000000000
SERVER: 0:success
```

## File Structure and Purpose

### Core Server Components

| File | Description |
|------|-------------|
| `fanuc_remote_server.kl` | Main server program that handles TCP connections and dispatches commands |
| `fanuc_remote_cmd.kl` | Command handler routines that implement the command processing logic |
| `fanuc_remote_comm.kl` | Communication utilities for opening/closing TCP connections |
| `fanuc_remote_utils.kl` | General utility functions used across the driver |
| `fanuc_remote_context.kl` | Manages kinematic context (tool, user frame, coordinate system) |
| `fanuc_remote_jog.kl` | Implements continuous jogging functionality similar to iPendant |
| `fanuc_remote_logger.kl` | Logging functionality for debugging and monitoring |

### Motion Execution Programs (TP)

| File | Description |
|------|-------------|
| `fanuc_remote_move.ls` | TP program for joint motion execution |
| `fanuc_remote_movel.ls` | TP program for linear motion execution |
| `fanuc_remote.ls` | Main entry point TP program |
| `SET_UTOOL_TP.ls` | TP program for setting the tool frame number |
| `SET_UFRAME_TP.ls` | TP program for setting the user frame number |

### Binary/PC Files

| File | Description |
|------|-------------|
| `FANUC_SVR.PC` | Compiled version of the server program |
| `FANUC_LOG.PC` | Compiled version of the logger program |

## Detailed Component Description

### fanuc_remote_server.kl

The main server program that:
- Initializes the TCP/IP server socket
- Accepts client connections
- Processes incoming commands by calling appropriate handlers
- Maintains global state variables for tool, user frame, and coordinate system
- Manages the jog tick task for continuous jogging operations

```karel
PROGRAM FANUC_SVR
VAR
    g_tool_num:         INTEGER
    g_uframe_num:       INTEGER
    g_coord_type:       INTEGER  -- 0=WORLD, 1=USER, 2=TOOL
...
```

### fanuc_remote_cmd.kl

Contains command handling routines for all supported operations:
- Motion commands (MOVEJ, MOVEP)
- Position queries (GET_CURPOS, GET_CURJPOS)
- Digital I/O operations (SET_DOUT, GET_DOUT, SET_RDO, GET_RDO)
- System variable access (SET_SYS_VAR)
- Frame selection (SET_TOOL, SET_USER, SET_COORD, GET_TOOL, GET_USER, GET_COORD)
- Jogging operations (JOG_START, JOG_STOP, JOG_STOP_ALL)

The main entry point is the `HANDLE_CMD` routine that dispatches to appropriate handlers.

### fanuc_remote_context.kl

Manages the robot's kinematic context:
- Stores and applies the tool frame, user frame, and coordinate system settings
- Provides the `APPLY_KINEMATIC_CONTEXT` routine used before motion execution
- Ensures consistent coordinate system behavior across operations

### fanuc_remote_jog.kl

Implements iPendant-like jogging functionality:
- Maintains state for active jogging axes and directions
- Processes incremental motion based on active jog commands
- Applies transformations based on coordinate system (WORLD/USER/TOOL)
- Executes small, continuous movements while a jog command is active
- Provides immediate stop functionality when jog is released

### fanuc_remote_comm.kl

Provides communication utilities:
- `OPEN_COMM`: Opens a TCP server socket
- `CLOSE_COMM`: Closes a TCP connection
- Handles the low-level socket operations

### fanuc_remote_utils.kl

Contains utility functions:
- String manipulation
- Command parsing
- Register access
- Position register manipulation
- Error handling

### Motion Programs

The LS files are TP programs that are called from KAREL to execute actual robot motion:
- `fanuc_remote_move.ls`: Executes joint motions using the PR[81] register
- `fanuc_remote_movel.ls`: Executes linear motions using the PR[81] register

### Frame Setting Programs

- `SET_UTOOL_TP.ls`: Sets the active tool frame number using R[84]
- `SET_UFRAME_TP.ls`: Sets the active user frame number using R[85]

## Command Reference

### Motion Commands

- `movej:<vel>:<acc>:<cnt>:<type>:<num_joints>:<j1>:<j2>:...:<j9>`: Joint motion
- `movep:<vel>:<acc>:<cnt>:<type>:<x>:<y>:<z>:<w>:<p>:<r>`: Cartesian motion

### Position Queries

- `curpos`: Get current Cartesian position
- `curjpos`: Get current joint position

### I/O Operations

- `setdout:<port>:<value>`: Set digital output
- `getdout:<port>`: Get digital output state
- `setrdo:<port>:<value>`: Set robot digital output
- `getrdo:<port>`: Get robot digital output state

### Frame Selection

- `set_tool <n>`: Set tool frame number
- `set_user <m>`: Set user frame number
- `set_coord <WORLD|USER|TOOL>`: Set coordinate system
- `get_tool`: Get current tool frame number
- `get_user`: Get current user frame number
- `get_coord`: Get current coordinate system

### Jogging Operations

- `jog_start <AXIS> <DIR> [SPEED] [STEP]`: Start continuous jogging
- `jog_stop <AXIS>`: Stop jogging specific axis
- `jog_stop_all`: Stop all jogging operations

Where:
- `<AXIS>`: One of X, Y, Z, W, P, R
- `<DIR>`: + or -
- `[SPEED]`: Optional percentage (default 25)
- `[STEP]`: Optional mm/deg per tick (defaults: 0.25 mm, 0.5 deg)

## Register Usage

The driver uses several robot registers for operation:
- `R[81]`: Motion velocity
- `R[82]`: Motion acceleration
- `R[83]`: CNT value for motion blending
- `R[84]`: Tool number for SET_UTOOL_TP
- `R[85]`: User frame number for SET_UFRAME_TP
- `PR[81]`: Position register for motion execution

## Security and Error Handling

- The driver validates all input parameters
- Motion commands check for position limits
- Error responses are provided for invalid commands
- Jogging commands include safety checks to prevent collisions
- Proper error recovery is implemented for fault conditions