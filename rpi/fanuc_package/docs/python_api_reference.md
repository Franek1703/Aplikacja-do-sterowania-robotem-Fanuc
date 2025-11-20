# FanucPy Python API Reference

Complete reference for the FanucPy Python library including all available methods, parameters, and communication protocols.

## Table of Contents

1. [Robot Class](#robot-class)
2. [Connection Management](#connection-management)
3. [Motion Commands](#motion-commands)
4. [Position Queries](#position-queries)
5. [Coordinate Frame Management](#coordinate-frame-management)
6. [Jogging Operations](#jogging-operations)
7. [I/O Operations](#io-operations)
8. [Program Execution](#program-execution)
9. [FTP Operations](#ftp-operations)
10. [Communication Protocols](#communication-protocols)

---

## Robot Class

### Constructor

```python
Robot(
    robot_model: str,
    host: str,
    port: int = 18735,
    ee_DO_type: str | None = None,
    ee_DO_num: int | None = None,
    socket_timeout: int = 60,
    ftp_user: str = "anonymous",
    ftp_password: str = "",
)
```

**Parameters:**
- `robot_model` (str): Robot model identifier (e.g., "Fanuc", "Kuka")
- `host` (str): IP address of the robot controller
- `port` (int): TCP port number for socket communication (default: 18735)
- `ee_DO_type` (str | None): End-effector digital output type ("RDO" or "DO")
- `ee_DO_num` (int | None): End-effector digital output number
- `socket_timeout` (int): Socket timeout in seconds (default: 60)
- `ftp_user` (str): FTP username (default: "anonymous")
- `ftp_password` (str): FTP password (default: "")

**Example:**
```python
from fanucpy import Robot

robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735,
    ee_DO_type="RDO",
    ee_DO_num=7,
    socket_timeout=60,
    ftp_user="anonymous",
    ftp_password=""
)
```

---

## Connection Management

### connect()

**Protocol:** TCP Socket

Establishes a connection to the robot controller via TCP socket.

```python
def connect() -> tuple[int, str]
```

**Returns:**
- `tuple[int, str]`: Response code (0=success, 1=error) and message

**Example:**
```python
code, message = robot.connect()
print(f"Connected: {message}")
```

**Raises:**
- `FanucError`: If connection fails or receives error response

---

### disconnect()

**Protocol:** TCP Socket + FTP

Closes the TCP socket connection and any active FTP connection.

```python
def disconnect() -> None
```

**Example:**
```python
robot.disconnect()
```

**Note:** Always disconnect when finished to free up resources.

---

## Motion Commands

All motion commands use **TCP Socket** communication.

### move()

Execute joint or Cartesian motion.

```python
def move(
    move_type: Literal["joint"] | Literal["pose"],
    vals: list,
    velocity: int = 25,
    acceleration: int = 100,
    cnt_val: int = 0,
    linear: bool = False,
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `move_type` (str): Movement type
  - `"joint"` or `"movej"`: Joint space motion
  - `"pose"` or `"movep"`: Cartesian space motion
- `vals` (list): Position values
  - For joint: `[j1, j2, j3, j4, j5, j6]` in degrees
  - For pose: `[x, y, z, w, p, r]` (mm and degrees)
- `velocity` (int): Velocity percentage (1-100) or mm/sec for linear motion
- `acceleration` (int): Acceleration percentage (1-100)
- `cnt_val` (int): CNT blending value (0-100)
  - 0 = FINE positioning (stop at target)
  - 1-100 = Blend through target (higher = smoother)
- `linear` (bool): Use linear motion (straight line in Cartesian space)
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Examples:**

```python
# Joint motion
robot.move(
    "joint",
    vals=[0, -90, 0, 0, 0, 0],
    velocity=50,
    acceleration=100,
    cnt_val=0,
    linear=False
)

# Cartesian motion with linear interpolation
robot.move(
    "pose",
    vals=[400, 0, 500, 180, 0, 180],
    velocity=100,
    acceleration=100,
    cnt_val=50,
    linear=True
)

# Smooth motion with blending
robot.move(
    "pose",
    vals=[450, 50, 550, 180, 0, 180],
    velocity=75,
    cnt_val=75,  # High CNT for smooth blending
    linear=True
)
```

**Raises:**
- `ValueError`: If movement type or parameters are invalid
- `FanucError`: If position is unreachable or motion fails

**Notes:**
- For linear motion, velocity is in mm/sec
- For joint motion, velocity is a percentage of maximum joint speed
- Higher CNT values create smoother paths but less accurate waypoint positioning

---

## Position Queries

All position query commands use **TCP Socket** communication.

### get_curpos()

Get the current Cartesian position of the tool center point.

```python
def get_curpos() -> list[float]
```

**Returns:**
- `list[float]`: `[x, y, z, w, p, r]` where:
  - `x, y, z`: Position in mm
  - `w, p, r`: Orientation in degrees (W-P-R Euler angles)

**Example:**
```python
position = robot.get_curpos()
print(f"Current position: X={position[0]}, Y={position[1]}, Z={position[2]}")
print(f"Current orientation: W={position[3]}, P={position[4]}, R={position[5]}")
```

---

### get_curjpos()

Get the current joint angles of the robot.

```python
def get_curjpos() -> list[float]
```

**Returns:**
- `list[float]`: Joint angles in degrees `[j1, j2, j3, j4, j5, j6, ...]`
  - Length depends on robot (6-9 joints typical)

**Example:**
```python
joints = robot.get_curjpos()
print(f"Joint angles: {joints}")
print(f"Joint 2 (shoulder): {joints[1]}°")
```

**Note:** Unused axes return "none" and are filtered out.

---

### get_ins_power()

Get the instantaneous power consumption of the robot.

```python
def get_ins_power() -> float
```

**Returns:**
- `float`: Power consumption in watts

**Example:**
```python
power = robot.get_ins_power()
print(f"Robot consuming {power:.2f} W")
```

---

## Coordinate Frame Management

All frame management commands use **TCP Socket** communication.

### set_tool()

Set the active tool frame number (UTOOL_NUM).

```python
def set_tool(
    tool_num: int,
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `tool_num` (int): Tool frame number (1-10)
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
# Set tool frame #5
robot.set_tool(5)
print("Tool frame set to 5")
```

**Notes:**
- Tool frames must be pre-configured on the robot controller
- Tool frame affects Cartesian positions and orientations

---

### get_tool()

Get the current active tool frame number.

```python
def get_tool(
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Returns:**
- `tuple[int, str]`: Response code and tool number as string

**Example:**
```python
code, tool_num = robot.get_tool()
print(f"Current tool frame: {tool_num}")
```

---

### set_user()

Set the active user frame number (UFRAME_NUM).

```python
def set_user(
    user_num: int,
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `user_num` (int): User frame number (0-9)
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
# Set user frame #2 (e.g., workpiece coordinate system)
robot.set_user(2)
```

**Notes:**
- User frames must be pre-configured on the robot controller
- User frame #0 is typically the robot base frame

---

### get_user()

Get the current active user frame number.

```python
def get_user(
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Returns:**
- `tuple[int, str]`: Response code and user frame number as string

**Example:**
```python
code, user_num = robot.get_user()
print(f"Current user frame: {user_num}")
```

---

### set_coord()

Set the active coordinate system for motion and jogging.

```python
def set_coord(
    coord_type: Literal["WORLD", "USER", "TOOL"],
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `coord_type` (str): Coordinate system to use
  - `"WORLD"`: Fixed to robot base, unaffected by user/tool frames
  - `"USER"`: Relative to active user frame
  - `"TOOL"`: Relative to tool orientation (Z-axis along tool)
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
# Use WORLD coordinates for absolute positioning
robot.set_coord("WORLD")

# Use USER coordinates for workpiece-relative movements
robot.set_user(3)
robot.set_coord("USER")

# Use TOOL coordinates for approach/retract operations
robot.set_coord("TOOL")
```

**Raises:**
- `ValueError`: If coord_type is not WORLD, USER, or TOOL

---

### get_coord()

Get the current active coordinate system.

```python
def get_coord(
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Returns:**
- `tuple[int, str]`: Response code and coordinate system ("WORLD", "USER", or "TOOL")

**Example:**
```python
code, coord_type = robot.get_coord()
print(f"Current coordinate system: {coord_type}")
```

---

## Jogging Operations

All jogging commands use **TCP Socket** communication.

Jogging provides iPendant-like continuous motion control. The robot moves continuously in the specified direction until stopped.

### jog_start()

Start continuous jogging of an axis.

```python
def jog_start(
    axis: Literal["X", "Y", "Z", "W", "P", "R"],
    direction: Literal["+", "-"],
    speed: int = None,
    step: float = None,
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `axis` (str): Axis to jog
  - Linear axes: "X", "Y", "Z"
  - Rotational axes: "W", "P", "R"
- `direction` (str): Direction to jog ("+" or "-")
- `speed` (int): Speed percentage (1-100), default is 75%
- `step` (float): Step size per tick
  - For X, Y, Z: mm per tick (default 2.0 mm)
  - For W, P, R: degrees per tick (default 1.0°)
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
import time

# Start jogging X+ at 50% speed
robot.jog_start("X", "+", speed=50)
time.sleep(2)  # Jog for 2 seconds
robot.jog_stop("X")

# Start jogging Z- with small steps for fine control
robot.jog_start("Z", "-", speed=25, step=0.5)
time.sleep(1)
robot.jog_stop("Z")

# Jog rotation
robot.jog_start("W", "+", speed=30, step=0.5)  # 0.5° per tick
```

**Raises:**
- `ValueError`: If axis or direction is invalid
- `FanucError`: If robot is busy or another axis is already active (single-axis mode)

**Notes:**
- Motion respects current coordinate system (WORLD/USER/TOOL)
- Default tick interval is 30ms
- Robot continues moving until `jog_stop()` is called
- Always stop jogging before executing other commands

---

### jog_stop()

Stop jogging of a specific axis.

```python
def jog_stop(
    axis: Literal["X", "Y", "Z", "W", "P", "R"],
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `axis` (str): Axis to stop jogging
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
robot.jog_stop("X")
```

**Raises:**
- `ValueError`: If axis is invalid

---

### jog_stop_all()

Stop all jogging operations immediately.

```python
def jog_stop_all(
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
# Emergency stop all jogging
robot.jog_stop_all()
```

---

## I/O Operations

All I/O commands use **TCP Socket** communication.

### gripper()

Control the end-effector gripper using configured digital output.

```python
def gripper(
    value: bool,
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `value` (bool): True to close gripper, False to open
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
# Close gripper
robot.gripper(True)

# Open gripper
robot.gripper(False)
```

**Raises:**
- `ValueError`: If `ee_DO_type` or `ee_DO_num` not configured in constructor

**Notes:**
- Requires `ee_DO_type` and `ee_DO_num` to be set in Robot constructor
- Uses either RDO or DO based on configuration

---

### set_rdo() / get_rdo()

Control Robot Digital Outputs (RDO).

```python
def set_rdo(
    rdo_num: int,
    val: bool,
    continue_on_error: bool = False,
) -> tuple[int, str]

def get_rdo(rdo_num: int) -> int
```

**Parameters:**
- `rdo_num` (int): RDO number (1-9)
- `val` (bool): Value to set (True/False)

**Returns:**
- `set_rdo()`: Response code and message
- `get_rdo()`: RDO value (0 or 1)

**Example:**
```python
# Set RDO #5 to ON
robot.set_rdo(5, True)

# Get RDO #5 state
state = robot.get_rdo(5)
print(f"RDO 5 is {'ON' if state else 'OFF'}")
```

**Notes:**
- RDO typically used for internal robot I/O and end-effector control

---

### set_dout() / get_dout()

Control Digital Outputs (DOUT).

```python
def set_dout(
    dout_num: int,
    val: bool,
    continue_on_error: bool = False,
) -> tuple[int, str]

def get_dout(dout_num: int) -> int
```

**Parameters:**
- `dout_num` (int): DOUT number (1-99999)
- `val` (bool): Value to set (True/False)

**Returns:**
- `set_dout()`: Response code and message
- `get_dout()`: DOUT value (0 or 1)

**Example:**
```python
# Control external device on DOUT #123
robot.set_dout(123, True)

# Read DOUT state
state = robot.get_dout(123)
```

**Notes:**
- DOUT used for external device control (conveyors, lights, etc.)

---

### set_sys_var()

Set a system variable on the robot controller.

```python
def set_sys_var(
    sys_var: str,
    val: bool,
    continue_on_error: bool = False,
) -> tuple[int, str]
```

**Parameters:**
- `sys_var` (str): System variable name (e.g., "$SCR.$COND_TIME")
- `val` (bool): Value to set (True/False)
- `continue_on_error` (bool): Don't raise exception on error

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
# Set a system variable
robot.set_sys_var("$SCR.$COND_TIME", True)
```

**Notes:**
- Currently only supports boolean system variables
- Requires knowledge of FANUC system variable names

---

## Program Execution

### call_prog()

**Protocol:** TCP Socket

Call an external TP program on the robot controller.

```python
def call_prog(prog_name: str) -> tuple[int, str]
```

**Parameters:**
- `prog_name` (str): Name of the TP program to execute

**Returns:**
- `tuple[int, str]`: Response code and message

**Example:**
```python
# Call gripper control program
robot.call_prog("GRIPPER_OPEN")

# Call custom pick routine
robot.call_prog("PICK_PART_A")
```

**Notes:**
- Program must exist on the robot controller
- Program executes synchronously (waits for completion)
- Useful for complex operations defined in TP programs

---

## FTP Operations

All FTP operations use the **FTP protocol** (port 21) and are separate from the TCP socket connection.

### list_programs()

List program files on the robot controller.

```python
def list_programs(
    device: str = "MD",
    pattern: str = "*",
    types: str = "ALL"
) -> List[str]
```

**Parameters:**
- `device` (str): Device to list files from
  - `"MD"`: Memory card (default)
  - `"UD1"`, `"UD2"`: USB drives
  - `"FR"`: FROM memory
- `pattern` (str): File pattern with wildcard support
  - `"*"`: All files
  - `"PICK_*"`: Files starting with "PICK_"
  - `"*_TEST"`: Files ending with "_TEST"
- `types` (str): File type filter
  - `"ALL"`: All files (default)
  - `"TP"`: TP programs only (.TP, .LS, .PC)
  - `"KAREL"`: KAREL programs only (.KL)

**Returns:**
- `List[str]`: List of filenames

**Example:**
```python
# List all TP programs
programs = robot.list_programs(device="MD", types="TP")
print(f"Found {len(programs)} TP programs:")
for prog in programs:
    print(f"  - {prog}")

# List programs matching pattern
pick_programs = robot.list_programs(device="MD", pattern="PICK_*")

# List KAREL programs
karel_programs = robot.list_programs(device="MD", types="KAREL")
```

**Raises:**
- `FanucError`: If FTP connection or listing fails

**Notes:**
- Automatically handles FTP connection/disconnection
- Returns list of filenames only (not full paths)

---

### read_program()

Read the contents of a program file from the robot controller.

```python
def read_program(device: str, filename: str) -> str
```

**Parameters:**
- `device` (str): Device to read from (e.g., "MD", "UD1")
- `filename` (str): Name of the file to read

**Returns:**
- `str`: File contents as a string

**Example:**
```python
# Read a TP program
content = robot.read_program("MD", "PICK_PLACE.TP")
print(content)

# Read a KAREL program
karel_code = robot.read_program("MD", "CUSTOM_LOGIC.KL")

# Parse program content
lines = content.splitlines()
for i, line in enumerate(lines, 1):
    print(f"{i:3d}: {line}")
```

**Raises:**
- `FanucError`: If FTP connection or file read fails

**Notes:**
- File must exist on the specified device
- Returns raw file content (no parsing)
- Automatically handles FTP connection/disconnection

---

## Communication Protocols

FanucPy uses two communication protocols:

### TCP Socket Communication (Port 18735)

**Used for:**
- Robot control commands (motion, I/O, queries)
- Real-time operations
- Coordinate frame management
- Jogging operations
- Program execution

**Characteristics:**
- Fast response time (5-200ms)
- Single persistent connection
- Text-based protocol
- Command-response pattern

**Connection:**
```python
robot = Robot(host="192.168.1.100", port=18735)
robot.connect()  # Establishes socket connection
```

**Example Commands:**
- `move()`, `get_curpos()`, `get_curjpos()`
- `set_tool()`, `set_user()`, `set_coord()`
- `jog_start()`, `jog_stop()`
- `set_rdo()`, `get_rdo()`, `set_dout()`, `get_dout()`
- `call_prog()`

---

### FTP Communication (Port 21)

**Used for:**
- File system access
- Program listing and reading
- File upload/download
- Directory management

**Characteristics:**
- Slower than socket (100-500ms)
- Separate connections per operation
- Standard FTP protocol
- No real-time capability

**Connection:**
```python
robot = Robot(
    host="192.168.1.100",
    ftp_user="anonymous",
    ftp_password=""
)
# FTP connection is automatic for FTP operations
programs = robot.list_programs()  # Auto-connects FTP
```

**Example Commands:**
- `list_programs()`
- `read_program()`

**Direct FTP Access:**
```python
from fanucpy.robot.ftp import RobotFTP

# Use FTP client directly for advanced operations
with RobotFTP(host="192.168.1.100") as ftp:
    # List files with detailed info
    files = ftp.list_files("MD:", "*", "ALL")
    
    # Write a new program
    ftp.write_text_file("MD:", "NEW_PROG.TP", program_content)
    
    # Create directory
    ftp.create_directory("MD:/MY_PROGRAMS")
    
    # Download file
    ftp.download_binary_file("MD:/DATA.BIN", "local_data.bin")
```

---

## Complete Example

```python
from fanucpy import Robot
import time

# Initialize robot with both socket and FTP configuration
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735,
    ee_DO_type="RDO",
    ee_DO_num=7,
    socket_timeout=60,
    ftp_user="anonymous",
    ftp_password=""
)

try:
    # Connect via TCP socket
    robot.connect()
    print("Connected to robot")
    
    # Set up coordinate system
    robot.set_tool(5)
    robot.set_user(2)
    robot.set_coord("USER")
    
    # Get current status
    position = robot.get_curpos()
    joints = robot.get_curjpos()
    power = robot.get_ins_power()
    print(f"Position: {position}")
    print(f"Joints: {joints}")
    print(f"Power: {power}W")
    
    # Perform motion
    robot.move(
        "joint",
        vals=[0, -90, 0, 0, 0, 0],
        velocity=50,
        acceleration=100,
        cnt_val=50,
        linear=False
    )
    
    # Use gripper
    robot.gripper(True)  # Close
    time.sleep(0.5)
    robot.gripper(False)  # Open
    
    # Jogging operation
    robot.jog_start("X", "+", speed=30)
    time.sleep(2)
    robot.jog_stop("X")
    
    # Call external program
    robot.call_prog("CUSTOM_ROUTINE")
    
    # List programs via FTP
    programs = robot.list_programs(device="MD", types="TP")
    print(f"\nFound {len(programs)} TP programs")
    
    # Read a program
    if programs:
        content = robot.read_program("MD", programs[0])
        print(f"\nFirst program ({programs[0]}):")
        print(content[:200] + "...")
    
finally:
    # Always disconnect
    robot.disconnect()
    print("\nDisconnected")
```

---

## Error Handling

All methods may raise `FanucError` exceptions:

```python
from fanucpy import Robot, FanucError

robot = Robot(robot_model="Fanuc", host="192.168.1.100")

try:
    robot.connect()
    robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
except FanucError as e:
    print(f"Robot error: {e}")
except ConnectionError as e:
    print(f"Connection error: {e}")
except ValueError as e:
    print(f"Invalid parameter: {e}")
finally:
    robot.disconnect()
```

---

## Summary

| Operation Category | Protocol | Port | Example Methods |
|-------------------|----------|------|-----------------|
| Motion Control | TCP Socket | 18735 | `move()`, `jog_start()` |
| Position Queries | TCP Socket | 18735 | `get_curpos()`, `get_curjpos()` |
| Frame Management | TCP Socket | 18735 | `set_tool()`, `set_user()`, `set_coord()` |
| I/O Control | TCP Socket | 18735 | `set_rdo()`, `set_dout()`, `gripper()` |
| Program Execution | TCP Socket | 18735 | `call_prog()` |
| File Access | FTP | 21 | `list_programs()`, `read_program()` |

**Key Differences:**
- **Socket operations**: Fast, real-time, single connection, control robot
- **FTP operations**: Slower, file management, auto-connect per operation, don't control robot directly

For more information, see:
- [Connection Guide](connection_guide.md)
- [FTP Access Guide](ftp_access.md)
- [Extended FTP Documentation](extended_ftp.md)

