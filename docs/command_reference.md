# FANUC Driver Command Reference

Quick reference guide for all available commands in the FANUC remote driver.

## Connection

### Server Configuration
- **Port:** 18735 (default)
- **Protocol:** TCP/IP
- **Format:** Text-based, newline-terminated commands
- **Response Format:** `<code>:<message>` where `0` = success, `1` = error

### Exit Server
```
exit
```
**Response:** `0:success`

Closes the current connection. Server continues listening for new connections.

---

## Position Queries

### Get Cartesian Position
```
curpos
```
**Response:** `0:x=<x>,y=<y>,z=<z>,w=<w>,p=<p>,r=<r>`

**Example Response:**
```
0:x=500.123,y=200.456,z=300.789,w=0.000,p=90.000,r=0.000
```

Position is in mm, orientation in degrees.

---

### Get Joint Position
```
curjpos
```
**Response:** `0:j=<j1>,j=<j2>,j=<j3>,j=<j4>,j=<j5>,j=<j6>[,j=<j7>,j=<j8>,j=<j9>]`

**Example Response:**
```
0:j=0.000,j=-90.000,j=0.000,j=0.000,j=0.000,j=0.000
```

Joint angles in degrees.

---

### Get Instantaneous Power
```
ins_pwr
```
**Response:** `0:<power_watts>`

**Example Response:**
```
0:1234.56
```

Power consumption in watts.

---

## Motion Commands

### Move to Joint Position
```
movej:<vel>:<acc>:<cnt>:<type>:<nj>:<j1>:<j2>:<j3>:<j4>:<j5>:<j6>[:<j7>:<j8>:<j9>]
```

**Parameters:**
- `<vel>`: Velocity, 4 digits with leading zeros (0001-0100) representing %
- `<acc>`: Acceleration, 4 digits (0001-0100) representing %
- `<cnt>`: CNT blending value, 3 digits (000-100)
- `<type>`: Motion type (0=joint, 1=linear)
- `<nj>`: Number of joints, 1 digit (6-9)
- `<j1>...<j9>`: Joint angles in degrees, 14 characters each (e.g., "+00000012.3456")

**Example (6-axis robot, joint motion, 50% speed):**
```
movej:0050:0100:050:0:6:+00000000.0000:-00000090.0000:+00000000.0000:+00000000.0000:+00000000.0000:+00000000.0000
```

**Response:** `0:success`

**Errors:**
- `1:R[81]-was-not-set` - Velocity register error
- `1:R[82]-was-not-set` - Acceleration register error
- `1:R[83]-was-not-set` - CNT register error
- `1:error-in-joint-values` - Invalid joint values
- `1:position-is-not-reachable` - Target outside workspace
- `1:PR[81]-was-not-set` - Position register error

---

### Move to Cartesian Position
```
movep:<vel>:<acc>:<cnt>:<type>:<nv>:<x>:<y>:<z>:<w>:<p>:<r>
```

**Parameters:**
- `<vel>`: Velocity, 4 digits (0001-0100 for %, or actual mm/sec for linear)
- `<acc>`: Acceleration, 4 digits (0001-0100) representing %
- `<cnt>`: CNT blending value, 3 digits (000-100)
- `<type>`: Motion type (0=joint, 1=linear)
- `<nv>`: Number of values, 1 digit (always 6)
- `<x>,<y>,<z>`: Position in mm, 14 characters each
- `<w>,<p>,<r>`: Orientation in degrees, 14 characters each

**Example (linear motion to X=500, Y=200, Z=300, W=0, P=90, R=0 at 50mm/sec):**
```
movep:0050:0100:050:1:6:+00000500.0000:+00000200.0000:+00000300.0000:+00000000.0000:+00000090.0000:+00000000.0000
```

**Response:** `0:success`

**Errors:** Same as `movej`

---

## Digital I/O

### Robot Digital Output (RDO)

#### Set RDO
```
setrdo:<n>:<value>
```
- `<n>`: RDO number, 1 digit (1-9)
- `<value>`: "true" or "false" (lowercase)

**Example:**
```
setrdo:5:true
```

**Response:** `0:success`

#### Get RDO
```
getrdo:<n>
```
- `<n>`: RDO number, 1 digit (1-9)

**Example:**
```
getrdo:5
```

**Response:** 
- `0:1` - RDO is ON
- `0:0` - RDO is OFF
- `1:wrong-rdo-value` - Error

---

### Digital Output (DOUT)

#### Set DOUT
```
setdout:<nnnnn>:<value>
```
- `<nnnnn>`: DOUT port number, 5 digits with leading zeros
- `<value>`: "true" or "false" (lowercase)

**Example:**
```
setdout:00123:true
```

**Response:** `0:success`

#### Get DOUT
```
getdout:<nnnnn>
```
- `<nnnnn>`: DOUT port number, 5 digits with leading zeros

**Example:**
```
getdout:00123
```

**Response:**
- `0:1` - DOUT is ON
- `0:0` - DOUT is OFF
- `1:wrong-dout-value` - Error

---

## Frame and Coordinate System

### Tool Frame

#### Set Tool Frame
```
set_tool:<n>
```
- `<n>`: Tool frame number (1-10)

**Example:**
```
set_tool:5
```

**Response:** `0:tool-set-success`

**Errors:**
- `1:cannot-set-r84` - Register error
- `1:cannot-run-set-utool-tp` - TP program error

#### Get Tool Frame
```
get_tool
```

**Response:** `0:<n>` where n is the current tool frame number

**Example Response:**
```
0:5
```

---

### User Frame

#### Set User Frame
```
set_user:<n>
```
- `<n>`: User frame number (0-9)

**Example:**
```
set_user:8
```

**Response:** `0:user-set-success`

**Errors:**
- `1:cannot-set-r85` - Register error
- `1:cannot-run-set-uframe-tp` - TP program error

#### Get User Frame
```
get_user
```

**Response:** `0:<n>` where n is the current user frame number

**Example Response:**
```
0:8
```

---

### Coordinate System

#### Set Coordinate System
```
set_coord:<system>
```
- `<system>`: "WORLD", "USER", or "TOOL" (uppercase)

**Example:**
```
set_coord:USER
```

**Response:** `0:coord-set-success`

**Error:** `1:invalid-coord-type`

**Coordinate Systems:**
- **WORLD:** Fixed to robot base, unaffected by user frame or tool orientation
- **USER:** Relative to active user frame, moves with workpiece coordinate system
- **TOOL:** Relative to tool orientation, X/Y/Z aligned with tool tip

#### Get Coordinate System
```
get_coord
```

**Response:** `0:<system>` where system is WORLD, USER, or TOOL

**Example Response:**
```
0:USER
```

---

## Jogging

### Start Jogging Axis
```
jog_start:<AXIS>:<DIR>:[SPEED]:[STEP]
```

**Parameters:**
- `<AXIS>`: Axis name - X, Y, Z, W, P, or R (uppercase)
- `<DIR>`: Direction - "+" or "-"
- `[SPEED]`: Optional speed percentage (1-100), default 75
- `[STEP]`: Optional step size:
  - For X,Y,Z: mm per tick (default 2.0)
  - For W,P,R: degrees per tick (default 1.0)

**Examples:**
```
jog_start:X:+                  # Jog X+ at default speed and step
jog_start:Z:-:50               # Jog Z- at 50% speed, default step
jog_start:Y:+:75:1.0           # Jog Y+ at 75% speed, 1.0mm per tick
jog_start:R:-:50:0.5           # Jog R- at 50% speed, 0.5° per tick
```

**Response:** `0:OK`

**Errors:**
- `1:ERR BUSY` - Robot is busy with other operation
- `1:ERR AXIS_ACTIVE` - Another axis already jogging (single-axis mode)
- `1:ERR INVALID_AXIS` - Invalid axis name
- `1:ERR INVALID_DIRECTION` - Invalid direction (must be + or -)
- `1:ERR OUT_OF_RANGE` - Speed not in range 1-100

**Notes:**
- Jogging continues until `jog_stop` or `jog_stop_all` is called
- Default tick interval is 30ms
- Motion respects current coordinate system (WORLD/USER/TOOL)
- Multi-axis jogging is disabled by default

---

### Stop Jogging Axis
```
jog_stop:<AXIS>
```

**Parameters:**
- `<AXIS>`: Axis name - X, Y, Z, W, P, or R (uppercase)

**Example:**
```
jog_stop:X
```

**Response:** `0:OK`

Stops jogging on the specified axis. Other axes continue jogging if active.

---

### Stop All Jogging
```
jog_stop_all
```

**Response:** `0:OK`

Immediately stops jogging on all axes.

---

## System Variables

### Set System Variable
```
setsysvar:<var_name>:<value>
```

**Parameters:**
- `<var_name>`: FANUC system variable path
- `<value>`: "T" (TRUE) or "F" (FALSE)

**Example:**
```
setsysvar:$SCR.$COND_TIME:T
```

**Response:** `0:success`

**Error:** `1:wrong-sys_var-value`

**Note:** Currently only supports boolean system variables. Requires knowledge of FANUC system variable naming.

---

## Program Execution

### Call TP Program
```
fanuccall:<program_name>
```

**Parameters:**
- `<program_name>`: Name of TP program to execute

**Example:**
```
fanuccall:GRIPPER_CLOSE
```

**Response:** `0:success`

**Notes:**
- Program must exist on the controller
- Can be used to trigger gripper operations, tool changes, etc.
- Program executes synchronously (command waits for completion)

---

## Response Codes

All commands return responses in the format: `<code>:<message>`

### Success Codes
- `0:success` - Generic success
- `0:OK` - Jogging command success
- `0:<data>` - Success with return data

### Error Codes
Error responses start with `1:` followed by an error message:

| Error Message | Description |
|---------------|-------------|
| `wrong-command` | Command not recognized |
| `position-is-not-reachable` | Target position outside robot workspace |
| `R[nn]-was-not-set` | Failed to set register |
| `PR[nn]-was-not-set` | Failed to set position register |
| `error-in-joint-values` | Invalid joint angle conversion |
| `cannot-convert-joint-vals` | Joint conversion error |
| `cannot-get-ins_pwr` | Power query failed |
| `wrong-rdo-value` | Invalid RDO value or number |
| `wrong-dout-value` | Invalid DOUT value or number |
| `wrong-sys_var-value` | Invalid system variable value |
| `invalid-coord-type` | Invalid coordinate system |
| `cannot-set-r84` | Tool number register error |
| `cannot-set-r85` | User frame register error |
| `cannot-run-set-utool-tp` | Tool setting TP program error |
| `cannot-run-set-uframe-tp` | User frame setting TP program error |
| `ERR BUSY` | Robot busy with other operation |
| `ERR AXIS_ACTIVE` | Another axis already jogging |
| `ERR INVALID_AXIS` | Invalid axis name |
| `ERR INVALID_DIRECTION` | Invalid direction |
| `ERR INVALID_ARGS` | Invalid command arguments |
| `ERR OUT_OF_RANGE` | Parameter out of valid range |

---

## Tips and Best Practices

### Motion Commands
1. **CNT Values:**
   - Use `CNT=0` for precise positioning (robot stops at target)
   - Use `CNT=50-100` for smooth continuous paths
   - Higher CNT = smoother but less accurate waypoint positioning

2. **Velocity:**
   - Joint motion: velocity is % of max joint speed (1-100)
   - Linear motion: velocity is in mm/sec (typical 1-2000)
   - Start with lower velocities (20-50%) for testing

3. **Position Format:**
   - Joint/Cartesian values must be exactly 14 characters
   - Use leading zeros and sign: "+00000123.4567"
   - Trailing zeros required for decimal places

### Jogging
1. **Always stop jogging before:**
   - Closing connection
   - Switching coordinate systems
   - Executing motion commands

2. **Coordinate Systems:**
   - WORLD: Best for simple Cartesian movements
   - USER: Best for workpiece-relative movements
   - TOOL: Best for tool-oriented movements (approach/retract)

3. **Speed and Step:**
   - Smaller steps (0.1-1.0mm) = smoother, more controllable
   - Larger steps (2.0-5.0mm) = faster traversal
   - Lower speed (25-50%) safer for manual control

### I/O
1. **RDO vs DOUT:**
   - RDO: Single-digit ports (1-9), typically internal robot functions
   - DOUT: Five-digit ports (00001-99999), external device control

2. **Always verify I/O state:**
   - Use `get` commands to confirm `set` operations
   - Check wiring and configuration if I/O doesn't respond

### Error Handling
1. **Always check response code:**
   - Parse first character: '0' = success, '1' = error
   - Log error messages for debugging

2. **Common issues:**
   - Position not reachable: Check joint limits and singularities
   - Register errors: May indicate robot is not in correct mode
   - TP program errors: Verify programs are loaded on controller

---

## Example Session

```
Client: curpos
Server: 0:x=500.123,y=200.456,z=300.789,w=0.000,p=90.000,r=0.000

Client: set_tool:5
Server: 0:tool-set-success

Client: set_coord:USER
Server: 0:coord-set-success

Client: movep:0050:0100:050:1:6:+00000550.0000:+00000200.0000:+00000300.0000:+00000000.0000:+00000090.0000:+00000000.0000
Server: 0:success

Client: setrdo:5:true
Server: 0:success

Client: getrdo:5
Server: 0:1

Client: jog_start:X:+:50:1.0
Server: 0:OK

Client: jog_stop:X
Server: 0:OK

Client: exit
Server: 0:success
```

---

## Python Example

```python
import socket

class FanucDriver:
    def __init__(self, host, port=18735):
        self.host = host
        self.port = port
        self.socket = None
    
    def connect(self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.connect((self.host, self.port))
        # Read initial response
        response = self.socket.recv(1024).decode().strip()
        return response
    
    def send_command(self, command):
        self.socket.send((command + '\n').encode())
        response = self.socket.recv(1024).decode().strip()
        return response
    
    def get_position(self):
        response = self.send_command('curpos')
        if response.startswith('0:'):
            # Parse: 0:x=500.123,y=200.456,...
            data = {}
            for pair in response[2:].split(','):
                key, value = pair.split('=')
                data[key] = float(value)
            return data
        else:
            raise Exception(f"Error: {response}")
    
    def move_joints(self, joints, vel=50, acc=100, cnt=50, motion_type=0):
        # Format joints as 14-character strings
        joint_strs = [f"{j:+014.7f}" for j in joints]
        nj = len(joints)
        
        cmd = f"movej:{vel:04d}:{acc:04d}:{cnt:03d}:{motion_type}:{nj}"
        cmd += ":" + ":".join(joint_strs)
        
        response = self.send_command(cmd)
        if not response.startswith('0:'):
            raise Exception(f"Move failed: {response}")
        return response
    
    def jog_start(self, axis, direction, speed=75, step=2.0):
        cmd = f"jog_start:{axis}:{direction}:{speed}:{step}"
        return self.send_command(cmd)
    
    def jog_stop(self, axis):
        return self.send_command(f"jog_stop:{axis}")
    
    def disconnect(self):
        if self.socket:
            self.send_command('exit')
            self.socket.close()

# Usage
if __name__ == "__main__":
    robot = FanucDriver('192.168.1.100')
    
    # Connect
    print(robot.connect())
    
    # Get current position
    pos = robot.get_position()
    print(f"Current position: {pos}")
    
    # Move to home position
    home_joints = [0, -90, 0, 0, 0, 0]
    robot.move_joints(home_joints, vel=50)
    
    # Jog X axis
    robot.jog_start('X', '+', speed=50, step=1.0)
    time.sleep(2)  # Jog for 2 seconds
    robot.jog_stop('X')
    
    # Disconnect
    robot.disconnect()
```

---

For detailed architecture information, see [driver_architecture.md](driver_architecture.md).

