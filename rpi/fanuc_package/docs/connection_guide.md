# Connection Guide

Complete guide to connecting to FANUC robots using FanucPy.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Network Configuration](#network-configuration)
3. [Robot Configuration](#robot-configuration)
4. [Python Connection](#python-connection)
5. [Connection Types](#connection-types)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Software Requirements

1. **Python 3.7 or higher**
   ```bash
   python --version
   ```

2. **FanucPy package**
   ```bash
   pip install -U fanucpy
   ```

### Hardware Requirements

1. **FANUC Robot Controller** with:
   - R-30iB, R-30iB Plus, or R-30iB Mate controller
   - Ethernet port (TCP/IP option)
   - FTP server enabled (for file operations)

2. **Computer** with:
   - Ethernet network interface
   - Network connectivity to robot controller

---

## Network Configuration

### Physical Connection

**Option 1: Direct Connection**
```
Computer ──────── Ethernet Cable ──────── Robot Controller
```

**Option 2: Network Switch**
```
Computer ──────┐
               ├─── Network Switch ──── Robot Controller
Other PCs ─────┘
```

### IP Address Setup

#### Robot Controller IP Configuration

1. On the teach pendant:
   - Press `MENU`
   - Select `SETUP`
   - Select `Host Comm`
   - Configure:
     - IP Address: e.g., `192.168.1.100`
     - Subnet Mask: e.g., `255.255.255.0`
     - Gateway: (if needed)

2. Verify TCP/IP is enabled:
   - `MENU` → `SETUP` → `Host Comm`
   - Check `TCP/IP ENABLED` is `TRUE`

#### Computer IP Configuration

**For direct connection, use static IP:**

**Windows:**
1. Control Panel → Network and Sharing Center
2. Change adapter settings
3. Right-click Ethernet → Properties
4. Select IPv4 → Properties
5. Set:
   - IP Address: `192.168.1.10` (same subnet as robot)
   - Subnet Mask: `255.255.255.0`
   - Gateway: (leave empty for direct)

**Linux:**
```bash
sudo ip addr add 192.168.1.10/24 dev eth0
```

**macOS:**
```bash
sudo ifconfig en0 inet 192.168.1.10 netmask 255.255.255.0
```

### Verify Network Connectivity

```bash
# Ping the robot
ping 192.168.1.100

# Expected output:
# Reply from 192.168.1.100: bytes=32 time<1ms TTL=64
```

If ping fails:
- Check cable connection
- Verify IP addresses are on same subnet
- Check firewall settings

---

## Robot Configuration

### Required Programs on Robot Controller

The FanucPy system requires KAREL and TP programs to be loaded on the robot controller:

1. **KAREL Programs** (*.kl, *.pc files):
   - `fanuc_remote_server.kl` / `FANUC_SVR.PC`
   - `fanuc_remote_cmd.kl`
   - `fanuc_remote_comm.kl`
   - `fanuc_remote_context.kl`
   - `fanuc_remote_jog.kl`
   - `fanuc_remote_utils.kl`
   - `fanuc_remote_logger.kl` / `FANUC_LOG.PC`

2. **TP Programs** (*.ls files):
   - `fanuc_remote.ls`
   - `fanuc_remote_move.ls`
   - `fanuc_remote_movel.ls`
   - `FANUC_REMOTE_JOG.ls`
   - `SET_UTOOL_TP.ls`
   - `SET_UFRAME_TP.ls`

### Installing Robot Programs

1. **Via FTP:**
   ```python
   from fanucpy.robot.ftp import RobotFTP
   
   with RobotFTP(host="192.168.1.100") as ftp:
       # Upload KAREL programs
       with open("FANUC_SVR.PC", "rb") as f:
           ftp.write_file("MD:", "FANUC_SVR.PC", f)
       
       # Upload TP programs
       with open("fanuc_remote_move.ls", "r") as f:
           ftp.write_text_file("MD:", "FANUC_REMOTE_MOVE.LS", f.read())
   ```

2. **Via Teach Pendant:**
   - Use USB drive to transfer files
   - `MENU` → `FILE` → `LOAD FILE` → Select files

3. **Via ROBOGUIDE:**
   - Simulate and test before deploying
   - Export to robot controller

### Starting the Server

**Manual Start (for testing):**
1. On teach pendant:
   - Press `SELECT`
   - Navigate to `FANUC_REMOTE` program
   - Press `RESET` (reset any alarms)
   - Set mode to `AUTO` (if needed)
   - Press `RUN` or `FWD`

**Expected output on teach pendant:**
```
FANUC_REMOTE SERVER started.
```

**Auto-start on boot (production):**
1. Configure as background task
2. `MENU` → `SETUP` → `APPLICATIONS`
3. Set `FANUC_REMOTE` to run on startup

### Verify Server is Running

```bash
# Check if port 18735 is listening
telnet 192.168.1.100 18735

# If server is running, you should see:
# 0:success
```

Press `Ctrl+]` then type `quit` to exit telnet.

---

## Python Connection

### Basic Connection

```python
from fanucpy import Robot

# Create robot instance
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",  # Robot controller IP
    port=18735,             # Default TCP port
)

# Connect
code, message = robot.connect()
print(f"Connection status: {message}")

# Use robot...
position = robot.get_curpos()
print(f"Current position: {position}")

# Always disconnect when done
robot.disconnect()
```

### Connection with Context Manager

```python
from fanucpy import Robot

class RobotConnection:
    """Context manager for robot connection."""
    def __init__(self, host, port=18735):
        self.robot = Robot(robot_model="Fanuc", host=host, port=port)
    
    def __enter__(self):
        self.robot.connect()
        return self.robot
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.robot.disconnect()
        return False

# Usage
with RobotConnection("192.168.1.100") as robot:
    position = robot.get_curpos()
    print(f"Position: {position}")
    # Robot automatically disconnects
```

### Connection with Error Handling

```python
from fanucpy import Robot, FanucError
import socket
import time

def connect_with_retry(host, max_attempts=3, delay=2):
    """Connect to robot with retry logic."""
    robot = Robot(robot_model="Fanuc", host=host, port=18735)
    
    for attempt in range(1, max_attempts + 1):
        try:
            print(f"Connection attempt {attempt}/{max_attempts}...")
            code, message = robot.connect()
            print(f"Connected successfully: {message}")
            return robot
        except (FanucError, socket.error, ConnectionError) as e:
            print(f"Attempt {attempt} failed: {e}")
            if attempt < max_attempts:
                print(f"Retrying in {delay} seconds...")
                time.sleep(delay)
            else:
                print("Max attempts reached. Connection failed.")
                raise
    
    return None

# Usage
try:
    robot = connect_with_retry("192.168.1.100", max_attempts=3)
    
    # Use robot
    robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
    
finally:
    robot.disconnect()
```

### Connection with Timeout

```python
from fanucpy import Robot
import socket

# Set custom timeout (default is 60 seconds)
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735,
    socket_timeout=30  # 30 second timeout
)

try:
    robot.connect()
    
    # Long-running operation won't block forever
    result = robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
    
except socket.timeout:
    print("Operation timed out")
except Exception as e:
    print(f"Error: {e}")
finally:
    robot.disconnect()
```

---

## Connection Types

FanucPy uses two connection types:

### 1. TCP Socket Connection (Control)

**Purpose:** Real-time robot control

**Configuration:**
```python
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735,              # TCP socket port
    socket_timeout=60        # Timeout in seconds
)

robot.connect()  # Establishes persistent socket connection
```

**Characteristics:**
- Persistent connection
- Fast response (5-200ms)
- Used for motion, I/O, queries
- Single connection per client
- Port: 18735 (default)

**Operations:**
- `move()` - Motion commands
- `get_curpos()`, `get_curjpos()` - Position queries
- `set_tool()`, `set_user()`, `set_coord()` - Frame management
- `jog_start()`, `jog_stop()` - Jogging
- `set_rdo()`, `set_dout()` - I/O control
- `call_prog()` - Program execution

### 2. FTP Connection (File Access)

**Purpose:** File system operations

**Configuration:**
```python
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    ftp_user="anonymous",    # FTP username
    ftp_password=""          # FTP password
)

# FTP auto-connects when needed
programs = robot.list_programs()
```

**Characteristics:**
- Auto-connect per operation
- Slower response (100-500ms)
- Used for file operations
- Port: 21 (FTP standard)
- Standard FTP protocol

**Operations:**
- `list_programs()` - List program files
- `read_program()` - Read program content

**Direct FTP Access:**
```python
from fanucpy.robot.ftp import RobotFTP

# Use FTP client directly
with RobotFTP(host="192.168.1.100", user="username", password="password") as ftp:
    files = ftp.list_files("MD:", "*", "ALL")
    content = ftp.read_file("MD:", "PROGRAM.TP")
    ftp.write_text_file("MD:", "NEW_PROG.TP", program_content)
```

### Both Connections in One Instance

```python
from fanucpy import Robot

# Configure both TCP and FTP
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    port=18735,              # TCP port
    socket_timeout=60,
    ftp_user="anonymous",    # FTP credentials
    ftp_password=""
)

# TCP operations
robot.connect()
position = robot.get_curpos()
robot.move("joint", vals=[0, -90, 0, 0, 0, 0])

# FTP operations (auto-connect)
programs = robot.list_programs()
content = robot.read_program("MD", programs[0])

# Disconnect both
robot.disconnect()
```

---

## Troubleshooting

### Connection Refused

**Symptoms:**
```
ConnectionRefusedError: [Errno 111] Connection refused
```

**Possible Causes:**
1. **Server not running on robot**
   - Check teach pendant for `FANUC_REMOTE SERVER started.`
   - Start the server: `SELECT` → `FANUC_REMOTE` → `RUN`

2. **Wrong IP address**
   - Verify robot IP: `MENU` → `SETUP` → `Host Comm`
   - Ping robot: `ping 192.168.1.100`

3. **Wrong port**
   - Default is 18735
   - Check if using custom port in server configuration

4. **Firewall blocking connection**
   - Disable firewall temporarily to test
   - Add exception for port 18735

**Solution:**
```python
# Verify server is reachable
import socket

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(5)
try:
    result = sock.connect_ex(("192.168.1.100", 18735))
    if result == 0:
        print("Port is open")
    else:
        print(f"Port is closed (error {result})")
except Exception as e:
    print(f"Connection test failed: {e}")
finally:
    sock.close()
```

---

### Timeout Errors

**Symptoms:**
```
socket.timeout: timed out
```

**Possible Causes:**
1. **Network latency**
2. **Robot busy with long operation**
3. **Server unresponsive**

**Solution:**
```python
# Increase timeout
robot = Robot(
    robot_model="Fanuc",
    host="192.168.1.100",
    socket_timeout=120  # Increase to 120 seconds
)
```

---

### FTP Connection Fails

**Symptoms:**
```
RobotFTPError: FTP connection failed: [Errno 111] Connection refused
```

**Possible Causes:**
1. **FTP server not enabled on robot**
   - Check: `MENU` → `SETUP` → `Host Comm` → `FTP ENABLED`

2. **Incorrect credentials**
   - Default: `user="anonymous"`, `password=""`
   - Some systems require actual credentials

3. **FTP port blocked**
   - Default FTP port is 21
   - Check firewall settings

**Solution:**
```python
from fanucpy.robot.ftp import RobotFTP, RobotFTPError

try:
    with RobotFTP(host="192.168.1.100", user="anonymous", password="") as ftp:
        files = ftp.list_files("MD:")
        print(f"FTP working: {len(files)} files found")
except RobotFTPError as e:
    print(f"FTP error: {e}")
    print("Check FTP is enabled on robot controller")
```

---

### Network Unreachable

**Symptoms:**
```
OSError: [Errno 101] Network is unreachable
```

**Possible Causes:**
1. **Computer and robot on different subnets**
2. **No network route**
3. **Cable unplugged**

**Solution:**
```bash
# Check IP configuration
# Computer: 192.168.1.10
# Robot:    192.168.1.100
# Must be same subnet: 192.168.1.x

# Windows
ipconfig

# Linux/Mac
ifconfig
```

---

### Robot Returns Error Responses

**Symptoms:**
```python
FanucError: position-is-not-reachable
FanucError: wrong-command
```

**Possible Causes:**
1. **Invalid position**
2. **Wrong command syntax**
3. **Robot in wrong mode**

**Solution:**
```python
# Use error handling
from fanucpy import Robot, FanucError

robot = Robot(robot_model="Fanuc", host="192.168.1.100")
robot.connect()

try:
    robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
except FanucError as e:
    print(f"Robot error: {e}")
    # Handle specific errors
    if "not-reachable" in str(e):
        print("Position is outside robot workspace")
    elif "wrong-command" in str(e):
        print("Command syntax error")
```

---

### Multiple Clients

**Problem:** Only one client can connect at a time

**Symptoms:**
```
FanucError: Connection refused (server busy)
```

**Explanation:**
- The FANUC server accepts only one TCP connection at a time
- Second connection attempt will fail

**Solution:**
```python
# Ensure previous connection is closed
try:
    robot1.disconnect()
except:
    pass

# Now connect with new client
robot2 = Robot(robot_model="Fanuc", host="192.168.1.100")
robot2.connect()
```

---

## Best Practices

### 1. Always Disconnect

```python
robot = Robot(robot_model="Fanuc", host="192.168.1.100")

try:
    robot.connect()
    # ... operations ...
finally:
    robot.disconnect()  # Always disconnect
```

### 2. Use Context Managers

```python
class RobotSession:
    def __init__(self, host):
        self.robot = Robot(robot_model="Fanuc", host=host)
    
    def __enter__(self):
        self.robot.connect()
        return self.robot
    
    def __exit__(self, *args):
        self.robot.disconnect()

with RobotSession("192.168.1.100") as robot:
    robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
```

### 3. Handle Errors Gracefully

```python
from fanucpy import Robot, FanucError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def safe_robot_operation(host):
    robot = Robot(robot_model="Fanuc", host=host)
    
    try:
        robot.connect()
        logger.info("Connected to robot")
        
        # Operations...
        robot.move("joint", vals=[0, -90, 0, 0, 0, 0])
        
    except FanucError as e:
        logger.error(f"Robot error: {e}")
        raise
    except ConnectionError as e:
        logger.error(f"Connection error: {e}")
        raise
    finally:
        robot.disconnect()
        logger.info("Disconnected from robot")
```

### 4. Verify Connection Status

```python
def check_robot_connection(host, port=18735):
    """Verify robot is reachable before connecting."""
    import socket
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(2)
    
    try:
        result = sock.connect_ex((host, port))
        return result == 0
    except Exception:
        return False
    finally:
        sock.close()

# Usage
if check_robot_connection("192.168.1.100"):
    robot = Robot(robot_model="Fanuc", host="192.168.1.100")
    robot.connect()
else:
    print("Robot not reachable, check network and server")
```

### 5. Monitor Connection Health

```python
import time
from fanucpy import Robot, FanucError

def monitor_robot_connection(host, check_interval=10):
    """Monitor robot connection and auto-reconnect."""
    robot = Robot(robot_model="Fanuc", host=host)
    
    while True:
        try:
            if not hasattr(robot, 'comm_sock') or robot.comm_sock is None:
                print("Connecting to robot...")
                robot.connect()
            
            # Send keepalive
            position = robot.get_curpos()
            print(f"Robot OK: {position}")
            
        except FanucError as e:
            print(f"Robot error: {e}")
            try:
                robot.disconnect()
            except:
                pass
            time.sleep(5)
        
        time.sleep(check_interval)
```

---

## Summary

**Connection Checklist:**

✅ Network configured (same subnet)  
✅ Robot controller IP set  
✅ Ping successful  
✅ FANUC server programs installed  
✅ FANUC_REMOTE server running  
✅ Port 18735 accessible  
✅ FTP enabled (for file operations)  
✅ Python code has correct IP and port  

**Quick Connection Test:**

```python
from fanucpy import Robot

robot = Robot(robot_model="Fanuc", host="192.168.1.100")

try:
    print("Connecting...")
    code, msg = robot.connect()
    print(f"Connected: {msg}")
    
    print("Getting position...")
    pos = robot.get_curpos()
    print(f"Position: {pos}")
    
    print("Connection successful!")
    
except Exception as e:
    print(f"Connection failed: {e}")
    
finally:
    robot.disconnect()
```

For more information:
- [Python API Reference](python_api_reference.md)
- [FTP Access Guide](ftp_access.md)
- [System Architecture](../../../docs/architecture.md)

