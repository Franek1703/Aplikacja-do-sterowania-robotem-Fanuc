# Jogging Functionality Documentation

## Overview

The jogging functionality provides iPendant-like control for 6 degrees of freedom (DOF): X, Y, Z, W, P, R with positive and negative directions, resulting in 12 possible control buttons. This feature allows continuous motion while a button is held down and immediate motion stop when the button is released.

## Implementation

The jogging system is implemented with the following components:

### KAREL Components

1. **fanuc_remote_jog.kl**: Core jogging functionality
   - Maintains jogging state (active axes, directions, speeds, steps)
   - Processes incremental motion based on active jog commands
   - Applies transformations based on coordinate system
   - Executes continuous small movements while jog is active

2. **fanuc_remote_cmd.kl** extensions:
   - Command handlers for JOG_START, JOG_STOP, JOG_STOP_ALL
   - Argument parsing and validation

3. **fanuc_remote_server.kl** integration:
   - Jog tick task that executes periodic jog movements
   - Initialization of jogging parameters

### Python Components

1. **robot.py** extensions:
   - `jog_start()`, `jog_stop()`, `jog_stop_all()` methods
   - Parameter validation and command construction

2. **cli_jog.py**:
   - Command-line interface for jogging operations
   - Support for all jogging parameters

## Protocol

### Commands

1. **JOG_START**:
   ```
   JOG_START <AXIS> <DIR> [SPEED] [STEP]
   ```
   Where:
   - `<AXIS>` is one of X, Y, Z, W, P, R
   - `<DIR>` is + or -
   - `[SPEED]` is an optional percentage (default 25)
   - `[STEP]` is an optional mm/deg per tick (defaults: 0.25 mm for XYZ, 0.5 deg for WPR)

2. **JOG_STOP**:
   ```
   JOG_STOP <AXIS>
   ```
   Where:
   - `<AXIS>` is one of X, Y, Z, W, P, R

3. **JOG_STOP_ALL**:
   ```
   JOG_STOP_ALL
   ```

### Responses

All jog commands return responses in the standard format: `<code>:<message>`

- Success responses: `0:OK`
- Error responses: 
  - `1:ERR BUSY` - Robot is busy with another operation
  - `1:ERR AXIS_ACTIVE` - Another axis is already being jogged (when multi-axis is disabled)
  - `1:ERR OUT_OF_RANGE` - Speed or step size out of valid range
  - `1:ERR INVALID_AXIS` - Invalid axis specified
  - `1:ERR INVALID_DIRECTION` - Invalid direction specified

## Operation

### Execution Flow

1. **Initialization**:
   - JOG_INIT is called during server startup
   - Default parameters are set (speed=25%, step=0.25mm/0.5deg, interval=30ms)
   - Jog tick task is started

2. **Jog Start**:
   - Client sends JOG_START command
   - Server validates parameters and updates jog state
   - Jog tick task begins applying incremental motion for active axis

3. **Continuous Motion**:
   - Jog tick task runs at regular intervals (default 30ms)
   - For each active axis, a small increment is applied
   - Motion continues until explicitly stopped

4. **Jog Stop**:
   - Client sends JOG_STOP or JOG_STOP_ALL command
   - Server updates jog state to deactivate axis/axes
   - Motion stops immediately at the next tick cycle

### Coordinate System Integration

The jogging functionality honors the current coordinate system set via SET_COORD:

1. **WORLD**: Increments are applied in world coordinates
2. **USER**: Increments are applied relative to the current user frame
3. **TOOL**: Increments are applied in the tool coordinate system

This allows intuitive jogging relative to different reference frames.

## Configuration

The following parameters are configurable:

1. **Speed**: Percentage (1-100) of maximum speed
2. **Step Size**:
   - Linear axes (X, Y, Z): Default 0.25 mm per tick
   - Rotational axes (W, P, R): Default 0.5 degrees per tick
3. **Interval**: Time between jog ticks (default 30ms)
4. **Multi-Axis**: Whether multiple axes can be jogged simultaneously (default: False)

## Usage Examples

### Python API

```python
from fanucpy.robot import Robot
import time

robot = Robot(robot_model="Fanuc", host="192.168.1.10")
robot.connect()

# Set coordinate system to TOOL
robot.set_coord("TOOL")

# Start jogging X+ at 30% speed
robot.jog_start("X", "+", speed=30)

# Wait for 2 seconds (simulating button press)
time.sleep(2)

# Stop jogging when button is released
robot.jog_stop("X")

robot.disconnect()
```

### Command Line

```bash
# Start jogging X+ at default speed
python cli_jog.py --host 192.168.1.10 start --axis X --dir +

# Start jogging Z- at 50% speed
python cli_jog.py --host 192.168.1.10 start --axis Z --dir - --speed 50

# Stop jogging X
python cli_jog.py --host 192.168.1.10 stop --axis X

# Stop all jogging
python cli_jog.py --host 192.168.1.10 stop-all
```

## Safety Considerations

1. **Motion Faults**: Jog commands are rejected if the robot is in fault or hold state
2. **Axis Limits**: The robot's built-in limits prevent jogging beyond safe ranges
3. **Immediate Stop**: Jogging stops immediately when a stop command is received
4. **One Axis at a Time**: By default, only one axis can be jogged at a time for safety
5. **Speed Control**: Speed is limited by the percentage parameter

## Implementation Notes

1. The jogging implementation uses the same motion execution mechanism as regular moves
2. Jog tick task runs as a background task to ensure responsive control
3. Proper error handling ensures that faults are reported to the client
4. The system respects the current kinematic context (tool, user frame, coordinate system)