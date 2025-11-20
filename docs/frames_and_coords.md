# Tool, User Frame, and Coordinate System Documentation

## Overview

This functionality allows the selection and management of:
- Tool frames (UTOOL)
- User frames (UFRAME) 
- Coordinate systems (WORLD/USER/TOOL)

These selections affect how robot movements are interpreted and executed, enabling more intuitive control in different reference frames.

## Implementation

The tool/user/coordinate system functionality is implemented with the following components:

### KAREL Components

1. **fanuc_remote_context.kl**:
   - Defines the `APL_KIN_CTX` routine
   - Manages tool, user frame, and coordinate system state
   - Applies the appropriate settings before motion execution

2. **fanuc_remote_cmd.kl** extensions:
   - Command handlers for SET_TOOL, SET_USER, SET_COORD
   - Command handlers for GET_TOOL, GET_USER, GET_COORD

3. **fanuc_remote_server.kl** integration:
   - Global state variables for tool, user frame, and coordinate system
   - Initialization of default values

4. **Bridge Programs**:
   - SET_UTOOL_TP.ls: TP program for setting tool frame
   - SET_UFRAME_TP.ls: TP program for setting user frame

### Python Components

1. **robot.py** extensions:
   - `set_tool()`, `get_tool()` methods
   - `set_user()`, `get_user()` methods
   - `set_coord()`, `get_coord()` methods

2. **cli_tool_user_coord.py**:
   - Command-line interface for tool/user/coord operations

## Protocol

### Commands

1. **Tool Frame Commands**:
   ```
   set_tool <tool_num>
   get_tool
   ```

2. **User Frame Commands**:
   ```
   set_user <user_num>
   get_user
   ```

3. **Coordinate System Commands**:
   ```
   set_coord <WORLD|USER|TOOL>
   get_coord
   ```

### Responses

All commands return responses in the standard format: `<code>:<message>`

- Tool/User Set Success: `0:tool-set-success`, `0:user-set-success`
- Tool/User Get Success: `0:<number>` (e.g., `0:3` for tool #3)
- Coord Set Success: `0:coord-set-success`
- Coord Get Success: `0:WORLD`, `0:USER`, or `0:TOOL`
- Error Responses: `1:<error-message>`

## Coordinate Systems

### WORLD Coordinate System

The WORLD coordinate system is the global reference frame of the robot. Movements in WORLD coordinates are relative to the robot base:

- X: Forward/backward from the robot base
- Y: Left/right from the robot base
- Z: Up/down from the robot base
- W/P/R: Rotations around X/Y/Z axes

### USER Coordinate System

The USER coordinate system is defined by a user frame (UFRAME). Movements in USER coordinates are relative to the specified user frame:

- X/Y/Z: Linear movement along user frame axes
- W/P/R: Rotations around user frame axes

This is useful for operations relative to workpieces or fixtures that may be positioned at different locations or orientations.

### TOOL Coordinate System

The TOOL coordinate system is defined by the current tool frame (UTOOL). Movements in TOOL coordinates are relative to the tool:

- X: Forward/backward from the tool
- Y: Left/right from the tool
- Z: Up/down from the tool
- W/P/R: Rotations around tool axes

This is useful for operations that need to move the tool in its local orientation, regardless of how the robot arm is positioned.

## Operation

### Execution Flow

1. **Setting Tool/User Frame**:
   - Client sends SET_TOOL or SET_USER command
   - Server updates global state
   - Server calls SET_UTOOL_TP or SET_UFRAME_TP TP program
   - Server applies the new kinematic context

2. **Setting Coordinate System**:
   - Client sends SET_COORD command
   - Server updates global state
   - Server applies the new kinematic context

3. **Motion Execution**:
   - Before any motion, `APL_KIN_CTX` is called
   - This ensures the current tool, user frame, and coordinate system are used

### Integration with Other Features

The tool/user/coordinate system settings affect:

1. **Regular Motion**: Both joint and Cartesian movements respect the current kinematic context
2. **Jogging Operations**: Incremental movements honor the coordinate system
3. **Position Reporting**: Position values are reported in the active frame

## Usage Examples

### Python API

```python
from fanucpy.robot import Robot

robot = Robot(robot_model="Fanuc", host="192.168.1.10")
robot.connect()

# Set tool #3
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

# Move 50mm in X in the tool direction
robot.move("pose", vals=[50, 0, 0, 0, 0, 0], linear=True)

robot.disconnect()
```

### Command Line

```bash
# Set tool #3
python cli_tool_user_coord.py --host 192.168.1.10 set_tool 3

# Set user frame #2
python cli_tool_user_coord.py --host 192.168.1.10 set_user 2

# Set coordinate system to TOOL
python cli_tool_user_coord.py --host 192.168.1.10 set_coord TOOL

# Get current settings
python cli_tool_user_coord.py --host 192.168.1.10 get_tool
python cli_tool_user_coord.py --host 192.168.1.10 get_user
python cli_tool_user_coord.py --host 192.168.1.10 get_coord
```

## Technical Details

### Register Usage

The implementation uses FANUC registers for operation:
- `R[84]`: Tool number for SET_UTOOL_TP
- `R[85]`: User frame number for SET_UFRAME_TP

### System Variables

The implementation interacts with FANUC system variables:
- `$MNUFRAMENUM[1]`: User frame number
- `$MNUTOOLNUM[1]`: Tool frame number
- `$MNCOORDSYS[1]`: Coordinate system (0=WORLD, 1=USER, 2=TOOL)
- `$MNUFRAME[1,n]`: User frame data for frame n
- `$MNUTOOL[1,n]`: Tool frame data for frame n

## Implementation Notes

1. Tool numbers and user frame numbers are typically 1-based (1-9)
2. The default tool is typically tool #1
3. The default user frame is typically user frame #1
4. The default coordinate system is WORLD
5. Changes to tool/user/coordinate settings affect subsequent motion commands
6. The kinematic context is applied before every motion to ensure consistency