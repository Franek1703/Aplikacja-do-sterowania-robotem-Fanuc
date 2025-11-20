# Firebase Gateway Architecture

Technical architecture documentation for the FANUC Firebase Gateway.

## Overview

The gateway acts as a bridge between Firebase (cloud) and FANUC robot controllers (local network). It runs on a Raspberry Pi and provides bidirectional communication.

```
┌─────────────────┐
│   Mobile App    │
│   (Flutter)     │
└────────┬────────┘
         │ Firebase SDK
         ▼
┌─────────────────┐
│    Firebase     │
│ ┌─────────────┐ │
│ │  Firestore  │ │  Static data (users, devices, robots)
│ └─────────────┘ │
│ ┌─────────────┐ │
│ │   RTDB      │ │  Live data (status, commands, FTP)
│ └─────────────┘ │
└────────┬────────┘
         │ Admin SDK
         ▼
┌─────────────────┐
│  Raspberry Pi   │
│   Gateway       │
│ ┌─────────────┐ │
│ │   Python    │ │  This package
│ │   Service   │ │
│ └─────────────┘ │
└────────┬────────┘
         │ Socket (18735) + FTP (21)
         ▼
┌─────────────────┐
│ FANUC Robot     │
│  Controller     │
│  (R-30iA/iB)    │
└─────────────────┘
```

## Component Architecture

### 1. Configuration Layer (`config.py`)

**Responsibility**: Load and validate settings

- Reads from environment variables or `.env` file
- Validates required fields
- Provides typed `Settings` dataclass
- Configures logging

**Key Settings**:
- Firebase credentials and URLs
- Device ID (unique identifier for this Pi)
- Robot connection parameters
- Simulation mode flag
- Status publish interval

### 2. Firebase Client (`firebase_client.py`)

**Responsibility**: Initialize and manage Firebase connections

- Singleton pattern for Firebase Admin SDK
- Provides access to Firestore and RTDB clients
- Handles reconnection logic
- Thread-safe initialization

**APIs**:
- `initialize_firebase(settings)` - One-time initialization
- `get_firestore_client()` - Get Firestore client
- `get_rtdb_root()` - Get RTDB root reference

### 3. Data Models (`models.py`)

**Responsibility**: Define data structures

All models follow `firebase_protocol.md` specification:

- `Command` - Robot command structure
- `FTPCommand` - FTP operation structure
- `CommandResult` - Execution result
- `RobotPose` - Cartesian position (XYZWPR)
- `RobotJoints` - Joint positions (J1-J6)
- `RobotConfig` - Tool, user frame, coord system
- `RobotStatus` - Online, mode, e-stop, alarms
- `DeviceStatus` - Gateway online status

All models have `to_dict()` and `from_dict()` methods for Firebase serialization.

### 4. Robot Adapter (`robot_adapter.py`)

**Responsibility**: Abstract robot interface

**RobotInterface Protocol**:
- Defines all robot operations
- Used by both real and simulated implementations

**RealRobotAdapter**:
- Wraps existing `Robot` class from `fanuc_package`
- Connects via socket to KAREL server on robot
- Implements all protocol methods

**SimulatedRobotAdapter**:
- In-memory robot simulation
- Logs all operations
- Updates internal state
- No hardware required

**Operations**:
- Motion: `move()`, `jog_start()`, `jog_stop()`
- Programs: `call_prog()`
- I/O: `set_rdo()`, `get_rdo()`, `set_dout()`, `get_dout()`
- Config: `set_tool()`, `set_user()`, `set_coord()`
- Status: `get_curpos()`, `get_curjpos()`, `get_power_consumption()`

### 5. FTP Bridge (`ftp_bridge.py`)

**Responsibility**: Handle FTP operations

Uses `RobotFTP` class from `fanuc_package` or simulated FTP.

**Operations**:
- `listFiles` - List files on robot
- `readFile` - Read file content
- `writeFile` - Write file to robot
- `deleteFile` - Delete file
- `renameFile` - Rename file
- `createDirectory` - Create directory
- `removeDirectory` - Remove directory

All operations return `CommandResult` with success/error status.

### 6. Command Dispatcher (`dispatcher.py`)

**Responsibility**: Route and execute commands

**Architecture**:
```python
command_handlers = {
    "move": _handle_move,
    "jogStart": _handle_jog_start,
    ...
}
```

**Flow**:
1. Receive `Command` or `FTPCommand`
2. Look up handler in mapping
3. Extract payload
4. Call robot/FTP method
5. Return `CommandResult`

**Error Handling**:
- Catches all exceptions
- Returns error result with message
- Logs errors for debugging

### 7. Status Publisher (`status_publisher.py`)

**Responsibility**: Publish robot status to Firebase

**Architecture**:
- Runs in separate thread
- Polls robot at configured interval (default 200ms)
- Updates multiple RTDB paths atomically

**Published Data**:
```
/devices/{deviceId}/status
  online: true
  lastSeen: <timestamp>

/devices/{deviceId}/robots/{robotId}/status
  online: true
  mode: "MANUAL"
  eStop: false
  alarmCount: 0

/devices/{deviceId}/robots/{robotId}/currentPose
  x, y, z, w, p, r
  updatedAt: <timestamp>

/devices/{deviceId}/robots/{robotId}/currentJoints
  j1, j2, j3, j4, j5, j6
  updatedAt: <timestamp>

/devices/{deviceId}/robots/{robotId}/config
  userFrame: 0
  toolNumber: 1
  coordSystem: "WORLD"
  activeProgram: null
```

**Thread Safety**:
- Uses daemon thread
- Graceful shutdown via `stop()` method
- Error handling prevents crashes

### 8. Command Listener (`command_listener.py`)

**Responsibility**: Listen for and execute commands

**Architecture**:
- Runs in separate thread
- Polls RTDB for new commands (every 500ms)
- Tracks processed commands to avoid duplicates
- Spawns worker threads for command execution

**Monitored Paths**:
```
/devices/{deviceId}/robots/{robotId}/commands/{commandId}
/devices/{deviceId}/robots/{robotId}/ftp/requests/{requestId}
```

**Command Lifecycle**:
1. Command created with `status: "pending"`
2. Listener detects new command
3. Updates status to `"running"`
4. Dispatches to handler
5. Updates result and status (`"success"` or `"error"`)

**FTP Response Path**:
```
/devices/{deviceId}/robots/{robotId}/ftp/responses/{requestId}
```

### 9. Main Application (`main.py`)

**Responsibility**: Orchestrate all components

**FirebaseGateway Class**:
```python
class FirebaseGateway:
    def setup():
        # Initialize Firebase
        # Create robot adapter
        # Connect to robot
        # Create FTP bridge
        # Create dispatcher
        # Create status publisher
        # Create command listener
    
    def start():
        # Start status publisher thread
        # Start command listener thread
    
    def stop():
        # Stop threads
        # Disconnect from robot
        # Cleanup
    
    def run():
        # Setup + Start + Keep alive
        # Handle signals (SIGINT, SIGTERM)
```

**Signal Handling**:
- Graceful shutdown on Ctrl+C
- Cleanup on SIGTERM
- Ensures robot disconnection

## Threading Model

```
Main Thread
├── Status Publisher Thread (daemon)
│   └── Polls robot every 200ms
│   └── Publishes to Firebase
│
├── Command Listener Thread (daemon)
│   ├── Polls Firebase every 500ms
│   └── Spawns worker threads for commands
│       ├── Worker Thread 1 (command execution)
│       ├── Worker Thread 2 (command execution)
│       └── ...
│
└── Signal Handler (main thread)
    └── Graceful shutdown
```

**Thread Safety**:
- Robot adapter: Single-threaded access (socket is not thread-safe)
- Firebase: Thread-safe (Admin SDK handles this)
- Command execution: Serialized via single robot connection

## Data Flow

### Status Publishing Flow

```
┌──────────────┐
│ Robot        │
│ Hardware     │
└──────┬───────┘
       │ Socket
       ▼
┌──────────────┐
│ Robot        │
│ Adapter      │
└──────┬───────┘
       │ get_curpos(), get_curjpos()
       ▼
┌──────────────┐
│ Status       │
│ Publisher    │
└──────┬───────┘
       │ RTDB write
       ▼
┌──────────────┐
│ Firebase     │
│ RTDB         │
└──────────────┘
```

### Command Execution Flow

```
┌──────────────┐
│ Mobile App   │
└──────┬───────┘
       │ Write command
       ▼
┌──────────────┐
│ Firebase     │
│ RTDB         │
└──────┬───────┘
       │ Poll
       ▼
┌──────────────┐
│ Command      │
│ Listener     │
└──────┬───────┘
       │ Dispatch
       ▼
┌──────────────┐
│ Dispatcher   │
└──────┬───────┘
       │ Call method
       ▼
┌──────────────┐
│ Robot        │
│ Adapter      │
└──────┬───────┘
       │ Socket command
       ▼
┌──────────────┐
│ Robot        │
│ Hardware     │
└──────────────┘
```

## Error Handling Strategy

### Levels of Error Handling

1. **Method Level**: Try-catch in individual methods
2. **Dispatcher Level**: Catch all command execution errors
3. **Thread Level**: Catch errors in thread loops
4. **Application Level**: Signal handlers for graceful shutdown

### Error Recovery

- **Transient Errors**: Retry with exponential backoff (future enhancement)
- **Connection Errors**: Log and continue (status publisher, command listener)
- **Command Errors**: Return error result to Firebase
- **Fatal Errors**: Log and exit gracefully

## Performance Considerations

### Status Publishing

- **Interval**: 200ms (configurable)
- **Data Size**: ~500 bytes per update
- **Network**: ~2.5 KB/s upload to Firebase
- **CPU**: Minimal (< 5% on RPi 3B+)

### Command Execution

- **Latency**: 100-500ms (network + robot)
- **Throughput**: ~10 commands/second
- **Concurrency**: Multiple commands via worker threads

### Memory Usage

- **Base**: ~50 MB (Python + Firebase SDK)
- **Runtime**: ~100 MB (with threads and buffers)
- **Peak**: ~150 MB (during heavy FTP operations)

## Security Considerations

### Firebase

- Service account key stored locally (600 permissions)
- Admin SDK has full access (runs on trusted Pi)
- RTDB rules should restrict client access

### Robot

- Socket connection (no encryption by default)
- FTP (no encryption by default)
- Should run on isolated network

### Raspberry Pi

- SSH key-based authentication recommended
- Firewall rules (only necessary ports)
- Regular security updates

## Scalability

### Single Robot

Current implementation supports one robot per gateway.

### Multiple Robots

To support multiple robots:

1. Modify `main.py` to create multiple robot adapters
2. Create separate status publishers per robot
3. Use single command listener (already supports multiple robots)
4. Update configuration to list robots

Example:

```python
robots = [
    {"id": "robotA", "host": "192.168.0.20"},
    {"id": "robotB", "host": "192.168.0.21"},
]

for robot_config in robots:
    robot = RealRobotAdapter(host=robot_config["host"])
    # Create publisher, listener, etc.
```

### Multiple Gateways

Multiple Raspberry Pis can run simultaneously:
- Each has unique `DEVICE_ID`
- Each manages its own robots
- Firebase handles concurrent access

## Testing Strategy

### Unit Tests

- `test_config.py` - Configuration validation
- `test_robot_adapter.py` - Simulated robot behavior
- `test_dispatcher.py` - Command routing

### Integration Tests

- `test_firebase.py` - Firebase connectivity
- Manual testing with real robot

### End-to-End Tests

- Mobile app → Firebase → Gateway → Robot
- Requires full system setup

## Monitoring and Debugging

### Logs

```bash
# Real-time logs
sudo journalctl -u fanuc-gateway -f

# Filter by level
sudo journalctl -u fanuc-gateway -p err

# Last hour
sudo journalctl -u fanuc-gateway --since "1 hour ago"
```

### Firebase Console

- Check RTDB for status updates
- Monitor command execution
- View FTP responses

### Debug Mode

```bash
export LOG_LEVEL=DEBUG
python3 -m fanuc_firebase_gateway.main
```

## Future Enhancements

1. **Retry Logic**: Exponential backoff for transient errors
2. **Health Checks**: Periodic robot connectivity tests
3. **Metrics**: Prometheus exporter for monitoring
4. **Alarms**: Real-time alarm parsing and publishing
5. **Video**: Camera feed integration
6. **Multi-Robot**: Native support for multiple robots
7. **WebSocket**: Alternative to polling for lower latency
8. **Encryption**: TLS for robot communication

