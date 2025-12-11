# FANUC Firebase Gateway

A production-ready Python package for bridging FANUC robots with Firebase (Firestore + Realtime Database). Runs on Raspberry Pi with **dynamic robot configuration** from Firestore.

## 🆕 Version 2.0 - Dynamic Configuration Architecture

**Major Change**: All robot configuration now comes from Firestore dynamically!

- ✅ **Auto-Registration**: Device auto-registers using MAC address
- ✅ **Dynamic Robot Selection**: Mobile app selects robot via Firebase  
- ✅ **No .env Robot Config**: Robot IP, port, credentials loaded from Firestore
- ✅ **Hot-Swapping**: Switch robots without restarting gateway

### How It Works

```
1. Gateway starts → Auto-registers as device_rpi_<MAC_ADDRESS>
2. Gateway watches /devices/{deviceId}/selectedRobotId in RTDB
3. Mobile app sets selectedRobotId = "robot123"
4. Gateway loads config from /robots/robot123 in Firestore:
   - ipAddress, tcpPort
   - ftpUser, ftpPassword
   - simulation mode
5. Gateway connects and starts processing commands
6. Mobile app can switch to different robot anytime
```

## Features

### Core Features
- **Dynamic Robot Configuration**: Load robot settings from Firestore dynamically
- **Auto Device Registration**: MAC-based device ID generation
- **Dual Database Registration**: Devices registered in both Firestore and Realtime Database
- **Two-way Firebase Communication**: Firestore for metadata + Realtime Database for live data
- **Complete Robot Control**: Motion, jogging, I/O, program execution, configuration
- **FTP Operations**: List, read, write, delete files and directories
- **Real-time Status Updates**: Publishes pose, joints, config at 200ms intervals
- **Hot-Swapping**: Switch robots without gateway restart
- **Dual Mode**: Real robot connection or simulation mode (per-robot setting)

### Production Features
- Comprehensive error handling and recovery
- Structured logging with configurable levels
- Graceful shutdown and cleanup
- Systemd service integration
- Thread-safe operations
- Type hints throughout
- Complete test suite

## Installation

### Prerequisites

- Python 3.10 or higher
- Firebase project with Admin SDK credentials
- FANUC robot with R-30iA or R-30iB controller

### Install Dependencies

```bash
cd rpi/fanuc_firebase_gateway
pip install -r requirements.txt
```

## Configuration

### Environment Variables (Minimal!)

Create a `.env` file with **ONLY Firebase credentials**:

```bash
# Firebase Configuration (REQUIRED)
FIREBASE_SERVICE_ACCOUNT=/path/to/serviceAccountKey.json
FIREBASE_RTDB_URL=https://your-project.firebaseio.com

# Operational Settings
STATUS_PUBLISH_INTERVAL=0.2
LOG_LEVEL=INFO
```

**That's it!** No more DEVICE_ID, ROBOT_HOST, ROBOT_PORT, SIMULATION, etc.

### Firebase Setup

#### 1. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Enable **Firestore Database** (Native mode)
4. Enable **Realtime Database**

#### 2. Generate Service Account Key

1. Go to Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Save JSON file to Raspberry Pi
4. Set path in `FIREBASE_SERVICE_ACCOUNT`

#### 3. Create Robot Document in Firestore

The mobile app typically creates robot documents, but you can create manually:

**Collection**: `/robots`  
**Document ID**: `robot_001` (or any unique ID)  
**Fields**:

```json
{
  "name": "FANUC R-2000iC/165F",
  "model": "R-2000iC/165F",
  "controller": "R-30iB",
  "ipAddress": "192.168.0.20",
  "tcpPort": 18735,
  "ftpUser": "anonymous",
  "ftpPassword": "",
  "simulation": false,
  "deviceId": null,
  "isOnline": false,
  "createdAt": "<timestamp>"
}
```

## Usage

### Start the Gateway

```bash
# The gateway will auto-register and wait for robot selection
python3 -m main
```

Expected output:

```
============================================================
FANUC Firebase Gateway
============================================================
  Device ID: device_rpi_a1b2c3d4e5f6

✓ Firebase initialized
✓ Device registered in Firestore
✓ Robot session manager created
✓ Device heartbeat started
✓ Robot session manager started

============================================================
FirebaseGateway started successfully
============================================================

Waiting for robot selection from mobile app...
Set /devices/device_rpi_a1b2c3d4e5f6/selectedRobotId in RTDB
```

### Select a Robot (Mobile App or Firebase Console)

In Firebase Console → Realtime Database, create/update:

**Path**: `/devices/device_rpi_<YOUR_MAC>/selectedRobotId`  
**Value**: `"robot_001"` (your robot document ID)

Gateway will automatically:
1. Load robot config from Firestore
2. Connect to robot
3. Start status publishing
4. Start command listening

### Switch Robots

Simply change `selectedRobotId` to a different robot ID. Gateway will:
1. Stop current robot session
2. Load new robot config
3. Connect to new robot
4. Resume operations

### Stop Robot Session

Set `selectedRobotId` to `null` or delete it. Gateway will stop all robot operations but keep running.

## Database Architecture

### Dual Database Registration

The gateway registers devices in **both** Firestore and Realtime Database:

#### Firestore: `/devices/{deviceId}`
```json
{
  "name": "RPi Gateway a1b2c3d4e5f6",
  "description": "Auto-registered device",
  "online": true,
  "lastSeen": "2025-11-20T10:30:00Z",
  "firmwareVersion": "2.0.1",
  "robotCount": 1,
  "robots": ["robot_001"],
  "ownerUid": "user123",
  "members": ["user456"]
}
```

#### Realtime Database: `/devices/{deviceId}/status`
```json
{
  "status": {
    "online": true,
    "lastSeen": 1700500000000
  }
}
```

**Why Both?**
- **Firestore**: Static metadata, ownership, robot list (mobile app queries)
- **RTDB**: Live status, fast updates, real-time listeners (mobile app monitors)

**Synchronization**:
- Both databases updated every 30 seconds by heartbeat
- Both marked offline on gateway shutdown
- RTDB uses Unix timestamps (milliseconds) for JavaScript compatibility
- Firestore uses native datetime objects

## Testing

### Test Device Registration

```bash
# Test dual database registration
python3 test_device_registration.py
```

This verifies:
- Device created in Firestore
- Device created in RTDB
- Heartbeat updates both databases
- Offline status set correctly

### Test Commands

```bash
# Make sure gateway is running and robot is selected
python3 test_commands.py
```

This sends test commands to Firebase RTDB and waits for results.

### Unit Tests

```bash
pytest tests/
```

## Firebase Data Structure

### Firestore (Static Data)

```
/devices/{deviceId}
  name: "RPi Gateway a1b2c3..."
  description: "Auto-registered device"
  ownerUid: null
  members: []
  online: true
  lastSeen: <timestamp>
  robotCount: 0
  robots: []

/robots/{robotId}
  name: "FANUC R-2000iC/165F"
  ipAddress: "192.168.0.20"
  tcpPort: 18735
  ftpUser: "anonymous"
  ftpPassword: ""
  simulation: false
  controller: "R-30iB"
  model: "R-2000iC/165F"
```

### Realtime Database (Live Data)

```
/devices/{deviceId}/
  selectedRobotId: "robot_001"
  status:
    online: true
    lastSeen: 1732023100
  robots/{robotId}/
    status: {...}
    currentPose: {...}
    currentJoints: {...}
    config: {...}
    commands/{commandId}: {...}
    ftp/
      requests/{requestId}: {...}
      responses/{requestId}: {...}
```

## Migration from v1.0

If you're upgrading from the old .env-based configuration, see **[MIGRATION.md](MIGRATION.md)** for detailed steps.

### Quick Migration Summary

**Old Way (.env)**:
```bash
DEVICE_ID=rpi_gateway_001
ROBOT_HOST=192.168.0.20
ROBOT_PORT=18735
ROBOT_FTP_USER=anonymous
SIMULATION=0
```

**New Way (Firestore + RTDB)**:
1. Remove robot settings from `.env` (keep only Firebase credentials)
2. Create robot document in Firestore `/robots/{robotId}` with IP, port, credentials
3. Gateway auto-generates device ID from MAC address
4. Mobile app sets `/devices/{deviceId}/selectedRobotId` in RTDB to connect

**Benefits**:
- ✅ No manual device configuration
- ✅ Centralized robot management
- ✅ Hot-swap robots without restart
- ✅ Multi-robot support ready

## Troubleshooting

### Gateway Can't Register Device

**Problem**: "Failed to register device"

**Solution**:
- Check Firebase credentials in `.env`
- Verify Firestore is enabled
- Check internet connectivity
- Review logs with `LOG_LEVEL=DEBUG`

### Robot Won't Connect

**Problem**: Gateway starts but no robot connection

**Solution**:
- Check `selectedRobotId` is set in RTDB
- Verify robot document exists in Firestore
- Check robot `ipAddress` and `tcpPort` are correct
- Test network: `ping <robot_ip>`
- Check robot KAREL server is running

### Device ID Changes

**Problem**: Device ID different each time

**Solution**:
- This shouldn't happen (MAC is stable)
- If it does, check network interface is consistent
- May need to specify interface in code

### Commands Not Executing

**Problem**: Commands stay in "pending" status

**Solution**:
- Verify robot is selected (`selectedRobotId` is set)
- Check gateway logs for errors
- Verify command format matches protocol
- Test with simple command like `getPowerConsumption`

## Advanced Usage

### Running Multiple Robots

The gateway can manage multiple robots by switching `selectedRobotId`:

1. Create multiple robot documents in Firestore
2. Switch between robots by changing `selectedRobotId` in RTDB
3. Gateway automatically stops old session and starts new one

### Simulation vs Real Mode

Simulation mode is now configured **per-robot** in Firestore:

```json
{
  "simulation": true  // or false
}
```

This allows you to have both simulated and real robots in the same system.

### Custom Status Intervals

Adjust status publishing frequency in `.env`:

```bash
STATUS_PUBLISH_INTERVAL=0.1  # 100ms (faster)
STATUS_PUBLISH_INTERVAL=0.5  # 500ms (slower, less bandwidth)
```

## Running as a Service

### Systemd Service

Create systemd service file:

```bash
sudo nano /etc/systemd/system/fanuc-gateway.service
```

```ini
[Unit]
Description=FANUC Firebase Gateway
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/fanuc_firebase_gateway
EnvironmentFile=/home/pi/fanuc_firebase_gateway/.env
ExecStart=/usr/bin/python3 -m main
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable fanuc-gateway
sudo systemctl start fanuc-gateway
sudo systemctl status fanuc-gateway
```

View logs:

```bash
sudo journalctl -u fanuc-gateway -f
```

## Documentation

- **README.md** - This file (user guide and quick start)
- **MIGRATION.md** - Migration guide from v1.0 to v2.0
- **ARCHITECTURE.md** - Technical architecture and design
- **PROJECT_SUMMARY.md** - Project overview and status
- **REFACTORING_SUMMARY.md** - Details of v2.0 refactoring
- **docs/firebase_protocol.md** - Complete Firebase protocol specification
- **INDEX.md** - Documentation navigation hub

## Protocol Reference

See `docs/firebase_protocol.md` for complete specifications:

### Command Types (20+ supported)
- **Motion**: move, jogStart, jogStop, jogStopAll
- **Programs**: runProgram, abortProgram, selectProgram
- **Gripper**: setGripper (open/close/toggle)
- **I/O**: setRDO, getRDO, setDOUT, getDOUT
- **Config**: setTool, setUserFrame, setCoord
- **Diagnostics**: getPowerConsumption, getRobotInfo
- **FTP**: listFiles, readFile, writeFile, deleteFile, renameFile, createDirectory, removeDirectory

### Firebase Structure
- **Firestore**: Static data (users, devices, robots)
- **Realtime Database**: Live data (status, commands, FTP operations)

## License

See LICENSE file for details.

## Project Statistics

- **Total Code**: ~3,700 lines of Python
- **Core Modules**: 12 files
- **Test Files**: 4 files
- **Documentation**: 8 files
- **Command Types**: 20+ implemented
- **FTP Operations**: 7 implemented
- **Test Coverage**: Core functionality covered

## Support & Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Device won't register | Check Firebase credentials, verify Firestore enabled |
| Robot won't connect | Verify `selectedRobotId` is set, check robot document exists |
| Commands not executing | Check robot is selected, verify command format |
| Status not updating | Check `STATUS_PUBLISH_INTERVAL`, verify RTDB rules |

### Getting Help

1. **Check Logs**: `sudo journalctl -u fanuc-gateway -f`
2. **Enable Debug**: Set `LOG_LEVEL=DEBUG` in `.env`
3. **Verify Setup**: Run `python3 test_commands.py`
4. **Review Docs**: Check `MIGRATION.md` and `ARCHITECTURE.md`
5. **Check Firebase**: Verify device and robot documents exist

### Debug Checklist

- [ ] Firebase credentials valid
- [ ] Firestore and RTDB enabled
- [ ] Device document exists in Firestore
- [ ] Robot document exists in Firestore
- [ ] `selectedRobotId` set in RTDB
- [ ] Robot IP/port correct
- [ ] Network connectivity to robot
- [ ] KAREL server running on robot

