# FANUC Firebase Gateway - Documentation Index

Complete documentation for the FANUC Firebase Gateway package.

## 📖 Getting Started

Start here if you're new to the project:

1. **[README.md](README.md)** 📘
   - **Start here!**
   - Project overview
   - Features and capabilities
   - Usage instructions
   - Configuration reference
   - Troubleshooting

2. **Installation** 🔧
   - See README.md for installation instructions
   - System requirements
   - Configuration
   - Service installation

## 🏗️ Technical Documentation

For developers and system architects:

3. **[ARCHITECTURE.md](ARCHITECTURE.md)** 🏛️
   - System architecture
   - Component design
   - Data flow diagrams
   - Threading model
   - Performance considerations
   - Security considerations

4. **[docs/firebase_protocol.md](docs/firebase_protocol.md)** 📋
   - Complete protocol specification
   - Firebase data model
   - Command reference
   - FTP operations
   - Status publishing format
   - **Single source of truth**

5. **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** 📊
   - Project overview
   - Implementation status
   - Technology stack
   - Code quality metrics
   - Known limitations
   - Future enhancements

## 📁 Package Structure

```
fanuc_firebase_gateway/
│
├── Core Python Modules (3,171 lines)
│   ├── __init__.py              # Package initialization
│   ├── config.py                # Configuration management
│   ├── firebase_client.py       # Firebase SDK wrapper
│   ├── models.py                # Data models
│   ├── robot_adapter.py         # Robot interface (Real + Simulated)
│   ├── ftp_bridge.py            # FTP operations
│   ├── dispatcher.py            # Command routing
│   ├── status_publisher.py      # Status publishing
│   ├── command_listener.py      # Command listening
│   └── main.py                  # Main application
│
├── Tests
│   └── tests/
│       ├── test_config.py       # Configuration tests
│       ├── test_dispatcher.py   # Dispatcher tests
│       └── test_robot_adapter.py # Robot adapter tests
│
├── Documentation (You are here!)
│   ├── INDEX.md                 # This file
│   ├── README.md                # User guide & installation
│   ├── ARCHITECTURE.md          # Technical architecture
│   ├── PROJECT_SUMMARY.md       # Project overview
│   └── docs/
│       └── firebase_protocol.md # Protocol specification
│
├── Configuration
│   ├── requirements.txt         # Python dependencies
│   ├── setup.py                 # Package installer
│   ├── pytest.ini               # Test configuration
│   ├── env.example              # Environment template
│   └── .gitignore               # Git ignore rules
│
├── Deployment
│   ├── fanuc-gateway.service    # Systemd service
│   ├── run_simulation.sh        # Quick start script
│   └── test_commands.py         # Command testing script
│
└── Protocol
    └── docs/firebase_protocol.md # Complete protocol spec
```

## 🎯 Common Tasks

### I want to...

**Get started quickly**
→ [README.md](README.md)

**Install on Raspberry Pi**
→ [README.md](README.md) (Installation section)

**Understand the architecture**
→ [ARCHITECTURE.md](ARCHITECTURE.md)

**Learn the command protocol**
→ [docs/firebase_protocol.md](docs/firebase_protocol.md)

**Configure the gateway**
→ [README.md](README.md) (Configuration section)

**Run tests**
→ [README.md](README.md) (Testing section)

**Deploy to production**
→ [README.md](README.md) (Running as a Service section)

**Troubleshoot issues**
→ [README.md](README.md) (Troubleshooting section)

**Add new commands**
→ [ARCHITECTURE.md](ARCHITECTURE.md) (Adding New Commands)

**Understand the code**
→ [ARCHITECTURE.md](ARCHITECTURE.md) + [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

## 📚 Reading Order

### For Users

1. [README.md](README.md) - Get it running and learn how to use it
2. [docs/firebase_protocol.md](docs/firebase_protocol.md) - Understand commands

### For Developers

1. [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Project overview
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Technical design
3. [docs/firebase_protocol.md](docs/firebase_protocol.md) - Protocol spec
4. Source code - Implementation details

### For System Administrators

1. [README.md](README.md) - Installation, configuration and troubleshooting
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Performance and security

## 🔑 Key Concepts

### Firebase Structure

```
Firestore (Static Data)
├── /users/{uid}
├── /devices/{deviceId}
└── /robots/{robotId}

Realtime Database (Live Data)
└── /devices/{deviceId}
    ├── /status
    └── /robots/{robotId}
        ├── /status
        ├── /currentPose
        ├── /currentJoints
        ├── /config
        ├── /commands/{commandId}
        └── /ftp/
            ├── /requests/{requestId}
            └── /responses/{requestId}
```

### Command Flow

```
Mobile App → Firebase RTDB → Gateway → Robot
                ↓
         Command Listener
                ↓
           Dispatcher
                ↓
         Robot Adapter
                ↓
         FANUC Robot
```

### Status Flow

```
FANUC Robot → Robot Adapter → Status Publisher → Firebase RTDB → Mobile App
```

## 📊 Statistics

- **Total Lines of Code**: 3,171+ (Python)
- **Core Modules**: 10 files
- **Test Files**: 3 files
- **Documentation**: 7 files
- **Command Types**: 20+ implemented
- **FTP Operations**: 7 implemented
- **Test Coverage**: Core functionality

## ✅ Feature Checklist

- ✅ Firebase integration (Firestore + RTDB)
- ✅ Robot control (motion, I/O, config)
- ✅ FTP operations (list, read, write, delete)
- ✅ Simulation mode (no hardware required)
- ✅ Real mode (FANUC robot)
- ✅ Status publishing (200ms interval)
- ✅ Command listening (500ms polling)
- ✅ Error handling
- ✅ Logging
- ✅ Type hints
- ✅ Docstrings
- ✅ Unit tests
- ✅ Documentation
- ✅ Deployment scripts
- ✅ Systemd service

## 🚀 Quick Commands

```bash
# Install
pip install -r requirements.txt

# Run simulation
./run_simulation.sh

# Test commands (in another terminal, with gateway running)
python3 test_commands.py

# Run real mode
python3 -m fanuc_firebase_gateway.main

# Run tests
pytest tests/

# Install service
sudo cp fanuc-gateway.service /etc/systemd/system/
sudo systemctl enable fanuc-gateway
sudo systemctl start fanuc-gateway

# View logs
sudo journalctl -u fanuc-gateway -f
```

## 🆘 Support

### Troubleshooting Steps

1. Check logs: `sudo journalctl -u fanuc-gateway -f`
2. Enable debug: `export LOG_LEVEL=DEBUG`
3. Test Firebase: `python3 test_firebase.py`
4. Test in simulation mode first
5. Review protocol: [docs/firebase_protocol.md](docs/firebase_protocol.md)

### Common Issues

| Issue | Solution |
|-------|----------|
| Firebase connection error | Check service account and RTDB URL |
| Robot connection error | Verify IP, port, and KAREL server |
| Commands not executing | Check command format and status |
| Status not updating | Check interval and Firebase rules |

## 📞 Contact

For issues and questions:
- Review documentation
- Check logs with debug level
- Test in simulation mode
- Verify protocol compliance

## 🎓 Learning Path

**Beginner** (Just want to use it)
1. README.md
2. Done!

**Intermediate** (Want to customize)
1. README.md
2. ARCHITECTURE.md
3. firebase_protocol.md

**Advanced** (Want to extend)
1. PROJECT_SUMMARY.md
2. ARCHITECTURE.md
3. firebase_protocol.md
4. Source code
5. Tests

## 📝 Version

- **Version**: 1.0.0
- **Status**: Production Ready ✅
- **Last Updated**: January 2025
- **Python**: 3.10+
- **Platform**: Raspberry Pi / Linux

---

**Start Here**: [README.md](README.md) ⚡

**Need Help**: [README.md](README.md) → Troubleshooting

**Want Details**: [ARCHITECTURE.md](ARCHITECTURE.md)

