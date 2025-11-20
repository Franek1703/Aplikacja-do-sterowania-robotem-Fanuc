# FANUC Firebase Gateway

A Python package for bridging FANUC robots with Firebase (Firestore + Realtime Database). Runs on Raspberry Pi and provides two-way communication between mobile apps and FANUC robot controllers.

## Features

- **Two-way Firebase Communication**: Reads/writes to Firestore and Realtime Database
- **Complete Robot Control**: Motion, jogging, I/O, program execution, configuration
- **FTP Operations**: List, read, write, delete files on robot controller
- **Real-time Status Updates**: Publishes robot pose, joints, and configuration at 200ms intervals
- **Simulation Mode**: Test Firebase integration without physical robot hardware
- **Production Ready**: Error handling, logging, graceful shutdown

## Architecture

The system follows the protocol defined in `docs/firebase_protocol.md`:

```
Mobile App (Flutter)
    ↓ Firebase
Raspberry Pi Gateway (this package)
    ↓ Socket + FTP
FANUC Robot Controller
```

## Installation

### Prerequisites

- Python 3.10 or higher
- Firebase project with Admin SDK credentials
- FANUC robot with R-30iA or R-30iB controller (for real mode)

### Install Dependencies

```bash
cd rpi/fanuc_firebase_gateway
pip install -r requirements.txt
```

### Test Installation

```bash
# Send test commands to Firebase (requires Firebase setup and running gateway)
python3 test_commands.py
```

### Required Python Packages

Create a `requirements.txt` file:

```
firebase-admin>=6.0.0
python-dotenv>=1.0.0
pytest>=7.0.0
```

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```bash
# Firebase Configuration (REQUIRED)
FIREBASE_SERVICE_ACCOUNT=/path/to/serviceAccountKey.json
FIREBASE_RTDB_URL=https://your-project.firebaseio.com
DEVICE_ID=rpi_gateway_001

# Robot Configuration
ROBOT_HOST=192.168.0.20
ROBOT_PORT=18735
ROBOT_FTP_USER=anonymous
ROBOT_FTP_PASSWORD=

# Operation Mode
SIMULATION=0                    # Set to 1 for simulation mode
STATUS_PUBLISH_INTERVAL=0.2     # Status update interval in seconds

# Logging
LOG_LEVEL=INFO                  # DEBUG, INFO, WARNING, ERROR
```

### Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Firestore and Realtime Database
3. Generate a service account key:
   - Go to Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file and set its path in `FIREBASE_SERVICE_ACCOUNT`

## Usage

### Simulation Mode (No Robot Required)

Test Firebase integration without physical hardware:

```bash
export SIMULATION=1
python -m fanuc_firebase_gateway.main
```

The simulated robot will:
- Log all commands to console
- Update internal state
- Publish fake status data to Firebase
- Respond to all commands successfully

### Real Mode (With FANUC Robot)

Connect to a real FANUC robot:

```bash
export SIMULATION=0
export ROBOT_HOST=192.168.0.20
python -m fanuc_firebase_gateway.main
```

Requirements:
- FANUC robot controller must have KAREL server programs installed
- Network connectivity between Raspberry Pi and robot
- FTP access enabled on robot controller

### Running as a Service

Create a systemd service file `/etc/systemd/system/fanuc-gateway.service`:

```ini
[Unit]
Description=FANUC Firebase Gateway
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/fanuc_firebase_gateway
EnvironmentFile=/home/pi/fanuc_firebase_gateway/.env
ExecStart=/usr/bin/python3 -m fanuc_firebase_gateway.main
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable fanuc-gateway
sudo systemctl start fanuc-gateway
sudo systemctl status fanuc-gateway
```

## Testing Commands

### Option 1: Use Test Script

Run the test script to send various commands:

```bash
# Make sure gateway is running first!
python3 test_commands.py
```

This will send:
- Get power consumption command
- Set tool command
- Move command
- Jog start command
- FTP list files request

### Option 2: Manual Testing via Firebase Console

In Firebase Console → Realtime Database, create a new node:

```
/devices/{deviceId}/robots/robotA/commands/{commandId}
```

With data:

```json
{
  "type": "move",
  "status": "pending",
  "createdAt": 1732023170,
  "createdBy": "test_user",
  "payload": {
    "mode": "pose",
    "vals": [450, 0, 300, 180, 0, 90],
    "velocity": 20,
    "acceleration": 100,
    "cnt": 0,
    "linear": true
  },
  "result": {
    "code": null,
    "message": null,
    "completedAt": null
  }
}
```

Watch the gateway logs and Firebase for the result.

### 2. Send a Jog Command

```json
{
  "type": "jogStart",
  "status": "pending",
  "createdAt": 1732023180,
  "createdBy": "test_user",
  "payload": {
    "axis": "X",
    "direction": "+",
    "speed": 25,
    "step": 0.5
  }
}
```

### 3. List FTP Files

Create under `/devices/{deviceId}/robots/robotA/ftp/requests/{requestId}`:

```json
{
  "type": "listFiles",
  "status": "pending",
  "createdAt": 1732023190,
  "createdBy": "test_user",
  "payload": {
    "device": "MD:",
    "pattern": "*.TP",
    "types": "TP"
  }
}
```

Check `/devices/{deviceId}/robots/robotA/ftp/responses/{requestId}` for results.

## Development

### Running Tests

```bash
pytest tests/
```

Run specific test file:

```bash
pytest tests/test_dispatcher.py -v
```

Run with coverage:

```bash
pytest --cov=fanuc_firebase_gateway tests/
```

### Project Structure

```
fanuc_firebase_gateway/
├── __init__.py              # Package initialization
├── config.py                # Configuration management
├── firebase_client.py       # Firebase initialization
├── models.py                # Data models (Command, Status, etc.)
├── robot_adapter.py         # Robot interface (Real + Simulated)
├── ftp_bridge.py            # FTP operations handler
├── dispatcher.py            # Command routing and execution
├── status_publisher.py      # Status publishing to Firebase
├── command_listener.py      # Command listening from Firebase
├── main.py                  # Main entry point
└── tests/                   # Unit tests
    ├── test_config.py
    ├── test_dispatcher.py
    └── test_robot_adapter.py
```

### Adding New Commands

1. Add command type to `models.py` (if needed)
2. Implement handler in `dispatcher.py`
3. Add to `command_handlers` mapping
4. Update `firebase_protocol.md` documentation
5. Add test in `tests/test_dispatcher.py`

## Logging

Logs are written to stdout with timestamps:

```
2025-01-20 10:30:45 - fanuc_firebase_gateway.main - INFO - FirebaseGateway started
2025-01-20 10:30:45 - fanuc_firebase_gateway.command_listener - INFO - Processing command: cmd_001
2025-01-20 10:30:46 - fanuc_firebase_gateway.dispatcher - INFO - Dispatching command: move
```

Adjust log level:

```bash
export LOG_LEVEL=DEBUG
```

## Troubleshooting

### Firebase Connection Issues

```
Error: Failed to initialize Firebase
```

- Check `FIREBASE_SERVICE_ACCOUNT` path is correct
- Verify service account JSON is valid
- Ensure `FIREBASE_RTDB_URL` is correct

### Robot Connection Issues

```
Error: Robot connection failed
```

- Verify `ROBOT_HOST` and `ROBOT_PORT`
- Check network connectivity: `ping 192.168.0.20`
- Ensure KAREL server is running on robot
- Check firewall settings

### Commands Not Executing

- Verify command format matches `firebase_protocol.md`
- Check `status` field is set to `"pending"`
- Review gateway logs for errors
- Ensure device_id and robot_id match configuration

## Protocol Reference

See `docs/firebase_protocol.md` for complete protocol specification including:

- All command types and payloads
- Firebase data structure
- FTP operations
- Status publishing format

## License

See LICENSE file for details.

## Support

For issues and questions:
- Check logs with `LOG_LEVEL=DEBUG`
- Review `firebase_protocol.md` for command format
- Verify Firebase data structure matches specification

