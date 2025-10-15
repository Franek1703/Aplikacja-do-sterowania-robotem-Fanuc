# FanucPy Python Library Documentation

## Overview

The `fanucpy` package is a Python interface for communicating with and controlling FANUC robots. It provides a high-level API that abstracts the underlying communication protocol and robot-specific details, allowing users to easily develop applications for robot control, automation, and integration with other systems.

## Module Structure

| Module | Description |
|--------|-------------|
| `robot.py` | Core robot connection and control functionality |
| `robotapp.py` | Application framework for building robot applications |
| `calibration.py` | Utilities for robot calibration |
| `transformations.py` | 3D transformation utilities |
| `__init__.py` | Package initialization and exports |

## Communication Architecture

The library uses a client-server architecture:

1. The Python code (client) connects to the fanuc_remote server running on the FANUC controller
2. Commands are sent as text strings over a TCP/IP socket
3. The server processes the commands and returns responses
4. The Python library parses the responses and raises exceptions or returns results

```
[Python Application] → [fanucpy] → TCP/IP → [fanuc_remote Server on FANUC] → [Robot Controller]
```

## Detailed Module Description

### robot.py

The `Robot` class is the main interface for communication with the physical robot. It handles:

- Connection establishment/teardown
- Command sending and response handling
- Motion control (joint and Cartesian)
- I/O operations
- Position queries
- Tool/User frame selection
- Coordinate system management
- Jogging operations

#### Core Methods

```python
class Robot:
    def __init__(self, robot_model, host, port=18735, ee_DO_type=None, ee_DO_num=None, socket_timeout=60)
    def connect() -> tuple[Literal[0, 1], str]
    def disconnect() -> None
    def send_cmd(cmd: str, continue_on_error=False) -> tuple[Literal[0, 1], str]
    def move(move_type: Literal["joint", "pose"], vals: list, velocity=25, acceleration=100, cnt_val=0, linear=False) -> tuple[Literal[0, 1], str]
    def get_curpos() -> list[float]
    def get_curjpos() -> list[float]
```

#### Tool/User Frame and Coordinate System Methods

```python
def set_tool(self, tool_num: int, continue_on_error=False) -> tuple[Literal[0, 1], str]
def get_tool(self, continue_on_error=False) -> tuple[Literal[0, 1], str]
def set_user(self, user_num: int, continue_on_error=False) -> tuple[Literal[0, 1], str]
def get_user(self, continue_on_error=False) -> tuple[Literal[0, 1], str]
def set_coord(self, coord_type: Literal["WORLD", "USER", "TOOL"], continue_on_error=False) -> tuple[Literal[0, 1], str]
def get_coord(self, continue_on_error=False) -> tuple[Literal[0, 1], str]
```

#### Jogging Methods

```python
def jog_start(self, axis: Literal["X", "Y", "Z", "W", "P", "R"], direction: Literal["+", "-"], speed=None, step=None, continue_on_error=False) -> tuple[Literal[0, 1], str]
def jog_stop(self, axis: Literal["X", "Y", "Z", "W", "P", "R"], continue_on_error=False) -> tuple[Literal[0, 1], str]
def jog_stop_all(self, continue_on_error=False) -> tuple[Literal[0, 1], str]
```

#### I/O Methods

```python
def gripper(self, value: bool, continue_on_error=False) -> tuple[Literal[0, 1], str]
def get_rdo(self, rdo_num: int) -> int
def set_rdo(self, rdo_num: int, val: bool, continue_on_error=False) -> tuple[Literal[0, 1], str]
def get_dout(self, dout_num: int) -> int
def set_dout(self, dout_num: int, val: bool, continue_on_error=False) -> tuple[Literal[0, 1], str]
```

### robotapp.py

The `RobotApp` class provides an application framework for robot applications. It:

- Manages the robot connection lifecycle
- Provides a standardized application structure
- Handles exceptions and error conditions

```python
class RobotApp:
    def __init__(self, robot_model, host, port=18735, ee_DO_type=None, ee_DO_num=None)
    def connect() -> bool
    def disconnect() -> bool
    def run() -> None  # Main method to override in subclasses
```

### calibration.py

Contains utilities for robot calibration, including:

- Hand-eye calibration
- Tool Center Point (TCP) calibration
- Base frame calibration

### transformations.py

Contains utilities for 3D transformations:

- Rotation matrices
- Quaternions
- Homogeneous transformations
- Euler angle conversions

## Command Line Tools

### cli_tool_user_coord.py

Command-line interface for controlling tool frames, user frames, and coordinate systems:

```
python cli_tool_user_coord.py --host <robot_ip> set_tool 3
python cli_tool_user_coord.py --host <robot_ip> set_user 2
python cli_tool_user_coord.py --host <robot_ip> set_coord TOOL
python cli_tool_user_coord.py --host <robot_ip> get_tool
```

### cli_jog.py

Command-line interface for jogging robot axes:

```
python cli_jog.py --host <robot_ip> start --axis X --dir +
python cli_jog.py --host <robot_ip> stop --axis X
python cli_jog.py --host <robot_ip> stop-all
```

## Usage Examples

### Basic Connection and Movement

```python
from fanucpy.robot import Robot

# Create robot instance
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.10",
    port=18735
)

# Connect to the robot
robot.connect()

# Move in joint space
robot.move(
    "joint",
    vals=[0, 0, 0, 0, 0, 0],
    velocity=50,
    acceleration=100,
    cnt_val=0
)

# Move in Cartesian space
robot.move(
    "pose",
    vals=[350, 0, 280, -15, -90, -160],
    velocity=100,
    acceleration=100,
    cnt_val=0,
    linear=True
)

# Disconnect
robot.disconnect()
```

### Using Tool, User Frames, and Coordinate Systems

```python
from fanucpy.robot import Robot

robot = Robot(robot_model="Fanuc", host="192.168.1.10")
robot.connect()

# Set tool, user frame, and coordinate system
robot.set_tool(3)
robot.set_user(2)
robot.set_coord("TOOL")

# Get current settings
code, tool_num = robot.get_tool()
code, user_num = robot.get_user()
code, coord_type = robot.get_coord()

print(f"Tool: {tool_num}, User: {user_num}, Coord: {coord_type}")

# Move in current coordinate system
robot.move("pose", vals=[10, 0, 0, 0, 0, 0], linear=True)  # Move 10mm in X in tool frame

robot.disconnect()
```

### Jogging Operations

```python
from fanucpy.robot import Robot
import time

robot = Robot(robot_model="Fanuc", host="192.168.1.10")
robot.connect()

# Start jogging X+ at 30% speed
robot.jog_start("X", "+", speed=30)

# Wait for 2 seconds (simulating button press)
time.sleep(2)

# Stop jogging when button is released
robot.jog_stop("X")

# Start jogging multiple axes (if allowed by server configuration)
robot.jog_start("Z", "-", speed=20)
time.sleep(1.5)

# Stop all jogging operations
robot.jog_stop_all()

robot.disconnect()
```

### Creating a Robot Application

```python
from fanucpy.robotapp import RobotApp

class MyPickPlaceApp(RobotApp):
    def run(self):
        # Application logic
        self.robot.set_coord("WORLD")
        
        # Move to pick position
        self.robot.move("pose", vals=[350, 0, 280, -15, -90, -160])
        
        # Close gripper
        self.robot.gripper(True)
        
        # Move to place position
        self.robot.move("pose", vals=[350, 200, 280, -15, -90, -160])
        
        # Open gripper
        self.robot.gripper(False)
        
        # Return to home position
        self.robot.move("joint", vals=[0, 0, 0, 0, 0, 0])

if __name__ == "__main__":
    app = MyPickPlaceApp(robot_model="Fanuc", host="192.168.1.10", ee_DO_type="RDO", ee_DO_num=7)
    app.connect()
    app.run()
    app.disconnect()
```

## Error Handling

The library provides robust error handling:

```python
from fanucpy.robot import Robot, FanucError

robot = Robot(robot_model="Fanuc", host="192.168.1.10")

try:
    robot.connect()
    robot.move("pose", vals=[9999, 0, 0, 0, 0, 0])  # Out of range
except FanucError as e:
    print(f"Robot error: {e}")
except ConnectionError as e:
    print(f"Connection failed: {e}")
finally:
    robot.disconnect()
```

## Socket Communication Details

The library communicates with the FANUC controller using a TCP/IP socket:

1. Socket creation and connection:
```python
self.comm_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
self.comm_sock.settimeout(self.socket_timeout)
self.comm_sock.connect((self.host, self.port))
```

2. Command sending:
```python
cmd = cmd.strip() + "\n"
self.comm_sock.sendall(cmd.encode())
```

3. Response receiving:
```python
resp = self.comm_sock.recv(self.sock_buff_sz).decode()
```

4. Response parsing:
```python
code_, msg = resp.split(":")
code = int(code_)
```

## Limitations and Considerations

1. **Network Reliability**: Ensure stable network connection between the client and robot controller
2. **Robot Limits**: Movement commands should respect joint and Cartesian limits
3. **Safety**: Implement proper safety checks in applications
4. **Performance**: Large movements may take time; adjust timeouts accordingly
5. **Error Recovery**: Implement proper error recovery mechanisms in production applications