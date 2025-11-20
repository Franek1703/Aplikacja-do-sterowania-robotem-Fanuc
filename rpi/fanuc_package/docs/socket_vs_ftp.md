# Socket vs FTP Communication

Quick reference guide comparing TCP Socket and FTP communication in FanucPy.

## Overview

FanucPy uses two separate communication protocols for different purposes:

| Protocol | Port | Purpose | Speed | Connection Type |
|----------|------|---------|-------|-----------------|
| **TCP Socket** | 18735 | Robot control & queries | Fast (5-200ms) | Persistent |
| **FTP** | 21 | File system access | Slower (100-500ms) | Auto-connect per operation |

---

## TCP Socket Communication

### What is it?

A persistent TCP connection to the FANUC robot controller running the `FANUC_SVR` KAREL server program.

### When to use:

- Real-time robot control
- Motion commands
- Position queries
- I/O operations
- Jogging
- Coordinate frame management

### Configuration:

```python
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735,              # TCP socket port
    socket_timeout=60        # Timeout in seconds
)

robot.connect()  # Establishes persistent connection
```

### Available Methods:

#### Motion Control
```python
# Move robot in joint space
robot.move("joint", vals=[0, -90, 0, 0, 0, 0])

# Move robot in Cartesian space
robot.move("pose", vals=[400, 0, 500, 180, 0, 180], linear=True)
```

#### Position Queries
```python
# Get current Cartesian position
position = robot.get_curpos()  # Returns [x, y, z, w, p, r]

# Get current joint angles
joints = robot.get_curjpos()  # Returns [j1, j2, j3, j4, j5, j6]

# Get power consumption
power = robot.get_ins_power()  # Returns watts
```

#### Frame Management
```python
# Set and get tool frame
robot.set_tool(5)
code, tool_num = robot.get_tool()

# Set and get user frame
robot.set_user(2)
code, user_num = robot.get_user()

# Set and get coordinate system
robot.set_coord("TOOL")  # WORLD, USER, or TOOL
code, coord_type = robot.get_coord()
```

#### Jogging Operations
```python
# Start continuous jogging
robot.jog_start("X", "+", speed=50, step=1.0)

# Stop jogging
robot.jog_stop("X")

# Stop all jogging
robot.jog_stop_all()
```

#### I/O Control
```python
# Robot Digital Output (RDO)
robot.set_rdo(7, True)
state = robot.get_rdo(7)

# Digital Output (DOUT)
robot.set_dout(123, False)
state = robot.get_dout(123)

# Gripper control (uses configured DO)
robot.gripper(True)  # Close
robot.gripper(False)  # Open
```

#### Program Execution
```python
# Call external TP program
robot.call_prog("PICK_ROUTINE")
```

#### System Variables
```python
# Set system variable
robot.set_sys_var("$SCR.$COND_TIME", True)
```

### Performance:

- **Latency:** 5-200ms depending on operation
- **Connection:** Single persistent connection
- **Concurrent clients:** Only 1 client at a time
- **Reliability:** High (TCP protocol guarantees)

### Protocol Details:

**Command Format:**
```
<command>:<param1>:<param2>:...\n
```

**Response Format:**
```
<code>:<message>
```
- Code 0 = Success
- Code 1 = Error

**Example Exchange:**
```
Client: curpos\n
Server: 0:x=500.123,y=200.456,z=300.789,w=0.000,p=90.000,r=0.000

Client: movej:0050:0100:050:0:6:+00000000.0000:-00000090.0000:...\n
Server: 0:success
```

---

## FTP Communication

### What is it?

Standard FTP (File Transfer Protocol) connection to the robot controller's FTP server for file system access.

### When to use:

- Listing program files
- Reading program contents
- Uploading new programs
- File management
- Directory operations

### Configuration:

```python
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    ftp_user="anonymous",    # FTP username
    ftp_password=""          # FTP password (usually empty)
)

# No explicit connect needed - FTP auto-connects
programs = robot.list_programs()
```

### Available Methods (via Robot class):

#### Program Listing
```python
# List all programs
all_programs = robot.list_programs(device="MD", pattern="*", types="ALL")

# List only TP programs
tp_programs = robot.list_programs(device="MD", types="TP")

# List KAREL programs
karel_programs = robot.list_programs(device="MD", types="KAREL")

# List with pattern matching
pick_programs = robot.list_programs(device="MD", pattern="PICK_*")
```

#### Program Reading
```python
# Read program content
content = robot.read_program("MD", "PROGRAM.TP")
print(content)
```

### Available Methods (via RobotFTP class):

For advanced FTP operations, use `RobotFTP` directly:

```python
from fanucpy.robot.ftp import RobotFTP

# Use as context manager
with RobotFTP(host="192.168.1.100", user="anonymous", password="") as ftp:
    # List files with detailed info
    files = ftp.list_files("MD:", "*", "ALL")
    for file in files:
        print(f"{file.name}: {file.size} bytes, {file.modify_time}")
    
    # Read file
    content = ftp.read_file("MD:", "PROGRAM.TP")
    
    # Write text file (TP program)
    ftp.write_text_file("MD:", "NEW_PROG.TP", program_content)
    
    # Write binary file
    ftp.write_file("MD:", "DATA.BIN", binary_data)
    
    # Directory operations
    pwd = ftp.get_pwd()
    ftp.change_directory("MD:/PROGRAMS")
    ftp.create_directory("MD:/NEW_FOLDER")
    ftp.remove_directory("MD:/OLD_FOLDER")
    
    # File operations
    ftp.rename_file("OLD.TP", "NEW.TP")
    ftp.remove_file("UNWANTED.TP")
    ftp.download_binary_file("MD:/PROGRAM.TP", "local_copy.tp")
```

### Supported Devices:

| Device | Description |
|--------|-------------|
| `MD:` | Memory card (internal storage) |
| `UD1:` | USB device 1 |
| `UD2:` | USB device 2 |
| `FR:` | FROM memory |
| `MO:` | Memory option |

### Supported File Types:

| Extension | Type | Description |
|-----------|------|-------------|
| `.TP`, `.LS` | TP | Teach Pendant programs |
| `.PC` | TP | Program control files |
| `.KL` | KAREL | KAREL programs |

### Performance:

- **Latency:** 100-500ms depending on file size
- **Connection:** Auto-connect per operation
- **Concurrent clients:** Multiple clients supported
- **Reliability:** High (standard FTP protocol)

### Protocol Details:

Standard FTP protocol (RFC 959):
- Uses FTP commands: `LIST`, `RETR`, `STOR`, `MKD`, `RMD`, etc.
- Binary and ASCII transfer modes
- Multiple encoding support: UTF-8, CP1252, ISO-8859-1

---

## Comparison Table

| Feature | TCP Socket | FTP |
|---------|------------|-----|
| **Purpose** | Robot control | File access |
| **Port** | 18735 | 21 |
| **Speed** | Fast (5-200ms) | Slower (100-500ms) |
| **Connection** | Persistent | Auto per operation |
| **Real-time** | Yes | No |
| **Concurrent clients** | 1 | Multiple |
| **Motion control** | ✅ Yes | ❌ No |
| **Position queries** | ✅ Yes | ❌ No |
| **I/O control** | ✅ Yes | ❌ No |
| **Jogging** | ✅ Yes | ❌ No |
| **File listing** | ❌ No | ✅ Yes |
| **File reading** | ❌ No | ✅ Yes |
| **File writing** | ❌ No | ✅ Yes |
| **Directory mgmt** | ❌ No | ✅ Yes |

---

## When to Use Which?

### Use TCP Socket for:

✅ Moving the robot  
✅ Reading current position/joints  
✅ Controlling I/O (grippers, lights, etc.)  
✅ Jogging operations  
✅ Setting tool/user frames  
✅ Executing TP programs  
✅ Any real-time operation  

**Example:**
```python
robot.connect()  # Connect socket
robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
position = robot.get_curpos()
robot.set_tool(5)
robot.jog_start("X", "+")
robot.disconnect()
```

### Use FTP for:

✅ Browsing program files  
✅ Reading program source code  
✅ Uploading new programs  
✅ Backup/restore programs  
✅ File management  
✅ Any file system operation  

**Example:**
```python
# List programs (FTP auto-connects)
programs = robot.list_programs(device="MD", types="TP")

# Read program
content = robot.read_program("MD", "PICK.TP")

# Advanced FTP operations
from fanucpy.robot.ftp import RobotFTP
with RobotFTP(host="192.168.1.100") as ftp:
    ftp.write_text_file("MD:", "NEW.TP", program_source)
```

---

## Using Both in One Session

You can use both socket and FTP in the same session:

```python
from fanucpy import Robot

# Initialize with both socket and FTP configuration
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735,           # Socket port
    ftp_user="anonymous", # FTP credentials
    ftp_password=""
)

# 1. Connect socket for control
robot.connect()

# 2. Use socket operations
position = robot.get_curpos()
print(f"Current position: {position}")

robot.move("joint", vals=[0, -90, 0, 0, 0, 0], velocity=50)

# 3. Use FTP operations (auto-connects)
programs = robot.list_programs(device="MD", types="TP")
print(f"Found {len(programs)} programs")

# 4. More socket operations
robot.set_tool(5)
robot.jog_start("X", "+", speed=30)

# 5. More FTP operations
if programs:
    content = robot.read_program("MD", programs[0])
    print(f"Program length: {len(content)} bytes")

# 6. Disconnect (closes both socket and FTP)
robot.disconnect()
```

---

## Error Handling

### Socket Errors:

```python
from fanucpy import Robot, FanucError
import socket

robot = Robot(robot_model="Fanuc", host="192.168.1.100")

try:
    robot.connect()
    robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
except FanucError as e:
    print(f"Robot error: {e}")
    # Robot-specific errors (position unreachable, etc.)
except socket.timeout:
    print("Socket operation timed out")
except ConnectionError as e:
    print(f"Connection error: {e}")
finally:
    robot.disconnect()
```

### FTP Errors:

```python
from fanucpy import Robot, FanucError
from fanucpy.robot.ftp import RobotFTPError

robot = Robot(robot_model="Fanuc", host="192.168.1.100")

try:
    programs = robot.list_programs()
except FanucError as e:
    # Wrapped FTP error from Robot class
    print(f"FTP error: {e}")

# Or with direct FTP access
from fanucpy.robot.ftp import RobotFTP

try:
    with RobotFTP(host="192.168.1.100") as ftp:
        files = ftp.list_files("MD:")
except RobotFTPError as e:
    # Direct FTP error
    print(f"FTP error: {e}")
```

---

## Network Requirements

### Socket Connection:

- **Port:** 18735 (TCP)
- **Firewall:** Must allow incoming/outgoing on port 18735
- **Server:** FANUC_SVR must be running on robot controller
- **Clients:** Only 1 concurrent connection

### FTP Connection:

- **Port:** 21 (FTP control), 20 (FTP data)
- **Firewall:** Must allow FTP traffic
- **Server:** FTP server must be enabled on robot controller
- **Clients:** Multiple concurrent connections supported

### Network Diagram:

```
Computer (192.168.1.10)
    │
    ├─── TCP Socket (Port 18735) ───→ FANUC_SVR Program
    │                                    │
    │                                    ├─ Motion commands
    │                                    ├─ Position queries
    │                                    ├─ I/O control
    │                                    └─ Jogging
    │
    └─── FTP (Port 21) ────────────→ FTP Server
                                        │
                                        ├─ File listing
                                        ├─ File reading
                                        └─ File writing

Robot Controller (192.168.1.100)
```

---

## Best Practices

### 1. Always Disconnect Socket

```python
robot = Robot(robot_model="Fanuc", host="192.168.1.100")

try:
    robot.connect()  # Socket connection
    # ... operations ...
finally:
    robot.disconnect()  # Closes socket AND FTP
```

### 2. FTP Auto-Connects

```python
# No need to explicitly connect FTP
robot = Robot(robot_model="Fanuc", host="192.168.1.100")

# FTP operations work without robot.connect()
programs = robot.list_programs()  # Auto-connects FTP
```

### 3. Use Socket for Time-Critical Operations

```python
# Fast operation - use socket
robot.connect()
position = robot.get_curpos()  # Fast: 5-10ms
robot.disconnect()

# Slow operation - FTP
programs = robot.list_programs()  # Slower: 100-500ms
```

### 4. Batch FTP Operations

```python
from fanucpy.robot.ftp import RobotFTP

# Efficient: Single FTP connection for multiple operations
with RobotFTP(host="192.168.1.100") as ftp:
    files = ftp.list_files("MD:")
    for file in files[:5]:
        content = ftp.read_file("MD:", file.name)
        # Process content...

# Inefficient: Multiple FTP connections
for i in range(5):
    content = robot.read_program("MD", f"PROG{i}.TP")  # New connection each time
```

### 5. Handle Both Connection Types

```python
def robot_operation(host):
    robot = Robot(robot_model="Fanuc", host=host)
    
    try:
        # Socket operations
        robot.connect()
        print("Socket connected")
        robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
        
        # FTP operations (auto-connect)
        programs = robot.list_programs()
        print(f"Found {len(programs)} programs")
        
    except FanucError as e:
        print(f"Operation error: {e}")
    finally:
        robot.disconnect()
        print("All connections closed")
```

---

## Summary

**Choose TCP Socket when:**
- You need to control the robot
- Speed is important
- Real-time operation required
- Working with motion, I/O, or queries

**Choose FTP when:**
- You need to access files
- Reading/writing programs
- File management tasks
- Speed is not critical

**Both protocols can coexist** in the same Robot instance and are used transparently based on the method called.

For more information:
- [Python API Reference](python_api_reference.md)
- [Connection Guide](connection_guide.md)
- [FTP Access Guide](ftp_access.md)

