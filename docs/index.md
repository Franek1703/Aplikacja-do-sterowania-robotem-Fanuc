# FanucPy Documentation

Welcome to the FanucPy documentation. This guide provides comprehensive information about using the FanucPy library and its associated tools for controlling FANUC robots.

## Documentation Sections

### System Architecture

- [**Architecture Overview**](architecture.md): Understand the overall design of the FanucPy system, including the communication protocol between the Python client and the KAREL server.

### Features

- [**Tool, User Frame, and Coordinate System**](frames_and_coords.md): Learn how to manage tool frames, user frames, and coordinate systems to control the reference frame for robot movements.

- [**Jogging Functionality**](jogging.md): Discover how to use the iPendant-like jogging functionality for continuous robot movement in all 6 degrees of freedom.

### Tools

- [**Command-Line Tools**](cli_tools.md): Explore the CLI utilities for robot control without writing Python code.

## Component Documentation

- [**KAREL/TP Driver**](../fanuc-driver/README.md): Documentation for the server-side KAREL and TP programs that run on the robot controller.

- [**Python Library**](../rpi/fanuc_package/src/robot/README.md): API reference for the Python client library.

## Example Applications

- [**Pick and Place App**](../rpi/fanuc_package/examples/PickAndPlaceApp.py): Example of a pick-and-place application using FanucPy.

- [**Aruco Tracking App**](../rpi/fanuc_package/examples/ArucoTrackingApp.py): Example of vision-based tracking using ArUco markers.

- [**ChatGPT Integration**](../rpi/fanuc_package/examples/fanucpy-gpt/README.MD): Example of using FanucPy with ChatGPT for natural language robot control.

- [**Voice Commands**](../rpi/fanuc_package/examples/voice-commands/README.md): Example of controlling the robot using voice commands.

## Getting Started

If you're new to FanucPy, we recommend starting with:

1. Installing the library: `pip install -U fanucpy`
2. Reading the [Architecture Overview](architecture.md) to understand the system
3. Exploring the [Python API examples](#python-api-examples) below
4. Trying the [Command-Line Tools](cli_tools.md) for quick testing

## Python API Examples

### Basic Connection

```python
from fanucpy.robot import Robot

robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735
)

robot.connect()
print(f"Connected to robot: {robot.get_curpos()}")
robot.disconnect()
```

### Moving the Robot

```python
# Move in joint space
robot.move(
    "joint",
    vals=[19.0, 66.0, -33.0, 18.0, -30.0, -33.0],
    velocity=100,
    acceleration=100,
)

# Move in Cartesian space with linear motion
robot.move(
    "pose",
    vals=[400, 0, 500, 180, 0, 180],
    linear=True,
    velocity=100,
    acceleration=100,
)
```

### Using Tool and User Frames

```python
# Set tool frame #3
robot.set_tool(3)

# Set user frame #2
robot.set_user(2)

# Set coordinate system to TOOL
robot.set_coord("TOOL")

# Move 50mm in X in the tool direction
robot.move("pose", vals=[50, 0, 0, 0, 0, 0], linear=True)
```

### Jogging Operations

```python
# Start jogging X+ at 30% speed
robot.jog_start("X", "+", speed=30)

# Wait for 2 seconds (simulating button press)
import time
time.sleep(2)

# Stop jogging
robot.jog_stop("X")
```

## Support and Contributions

For support or to contribute to the project, please visit the project repository.