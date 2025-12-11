📘 FANUC Remote Robot Platform – Firebase Database & Command Protocol
This document defines the complete Firebase architecture, communication protocol, and command set for the Mobile Fanuc Controller application communicating with Raspberry Pi Gateways and FANUC robots.

1. System Overview
The system consists of:
1. Mobile App (Flutter/iOS/Android)
    * Displays devices, robots, alarms, FTP files, parameters
    * Sends robot commands (jogging, moves, program execution, I/O, FTP actions) via Firebase
2. Firebase (Auth, Firestore, Realtime Database)
    * Firestore → users, devices, static robot metadata
    * Realtime Database → command channel, live robot status, FTP operations, alarms
3. Raspberry Pi Gateway (Python Service)
    * Runs your Robot and RobotFTP classes
    * Connects to FANUC R-30iA/R-30iB controller over Ethernet (KAREL + FTP)
    * Subscribes to Firebase Realtime Database
    * Executes commands & publishes results
4. FANUC Robot
    * Responds to KAREL server commands
    * Provides FTP access for programs, configs, logs

2. Firestore Data Model (Static Data)
Firestore stores persistent, non-live metadata.

2.1 Collection /users/{uid}
{
  "email": "engineer@company.com",
  "displayName": "John Engineer",
  "role": "engineer",        // "admin" | "engineer" | "viewer"
  "createdAt": "<timestamp>",
  "lastLoginAt": "<timestamp>",
  "company": "ACME Robotics"
}

2.2 Collection /devices/{deviceId} (Raspberry Pi gateways)
{
  "name": "Production Line A Gateway",
  "description": "RPi in Electrical Cabinet #3",
  "ownerUid": "uid123",
  "members": ["uid123", "uid456"],
  "location": {
    "plant": "Factory 1",
    "area": "Line A"
  },
  "online": true,
  "lastSeen": "<timestamp>",
  "firmwareVersion": "1.0.0",
  "robotCount": 4
}

2.3 Collection /robots/{robotId}
{
  "deviceId": "device123",
  "name": "FANUC R-2000iC/165F",
  "series": "R-2000iC Series",
  "model": "R-2000iC/165F",
  "controller": "R-30iB",
  "ipAddress": "192.168.0.20",
  "tcpPort": 18735,
  "ftpUser": "anonymous",
  "ftpPassword": "",
  "isOnline": true,
  "lastSeen": "<timestamp>",
  "createdAt": "<timestamp>"
}

3. Realtime Database Model (Live Data + Commands)
RTDB handles all dynamic info.
Root structure:
/devices/{deviceId}/...

3.1 Device & Robot Live Status
{
  "status": {
    "online": true,
    "lastSeen": 1732023100
  },
  "robots": {
    "robotA": {
      "status": {
        "online": true,
        "mode": "AUTO",        // T1, T2, MANUAL, AUTO
        "eStop": false,
        "alarmCount": 1
      },
      "currentPose": {
        "x": 450.25,
        "y": -125.8,
        "z": 320.15,
        "w": 180.0,
        "p": 0.0,
        "r": 90.0,
        "updatedAt": 1732023120
      },
      "currentJoints": {
        "j1": 45.5,
        "j2": -30.2,
        "j3": 60.8,
        "j4": 0.0,
        "j5": 45.0,
        "j6": 0.0,
        "updatedAt": 1732023120
      },
      "config": {
        "userFrame": 0,
        "toolNumber": 1,
        "coordSystem": "WORLD",
        "activeProgram": "MAIN001"
      },
      "parameters": {
        "1": {
          "value": "",
          "updatedAt": 1732023120,
          "updatedBy": "system"
        },
        "2": {
          "value": 100,
          "updatedAt": 1732023115,
          "updatedBy": "uid123"
        },
        "3": {
          "value": true,
          "updatedAt": 1732023100,
          "updatedBy": "system"
        },
        "4": {
          "value": "192.168.1.100",
          "updatedAt": 1732023090,
          "updatedBy": "system"
        }
      }
    }
  }
}

4. Command Channel Specification
Commands are written into:
/devices/{deviceId}/robots/{robotId}/commands/{commandId}
Each command:
{
  "type": "move",
  "status": "pending",      // pending | running | success | error
  "createdAt": 1732023170,
  "createdBy": "uid123",
  "payload": { ... },
  "result": {
    "code": null,
    "message": null,
    "completedAt": null
  }
}
RPi listens for status="pending" → executes → updates result.

5. Full Command List (All Supported Robot Operations)
Below is the complete unified command set.

5.1 Motion Commands
move
{
  "type": "move",
  "payload": {
    "mode": "pose",        // pose | joint
    "vals": [x,y,z,w,p,r] or [j1..j6],
    "velocity": 20,
    "acceleration": 100,
    "cnt": 0,
    "linear": true
  }
}
jogStart
{
  "type": "jogStart",
  "payload": {
    "axis": "X",          // X,Y,Z,W,P,R
    "direction": "+",     // + | -
    "speed": 25,
    "step": 0.25
  }
}
jogStop
{ "type": "jogStop", "payload": {"axis": "X"} }
jogStopAll
{ "type": "jogStopAll" }

5.2 Program Execution
runProgram
Runs a TP or KAREL program.
{
  "type": "runProgram",
  "payload": {
    "name": "MAIN001"
  }
}
abortProgram
{ "type": "abortProgram" }
selectProgram
{
  "type": "selectProgram",
  "payload": {
    "name": "MAIN001"
  }
}

5.3 Gripper Control
setGripper
(Over Ethernet → internally handled by digital outputs)
{
  "type": "setGripper",
  "payload": {
    "state": "open"   // open | close | toggle
  }
}

5.4 Robot I/O
setRDO / getRDO
RDO = Robot Digital Output
{
  "type": "setRDO",
  "payload": {
    "index": 5,
    "value": true
  }
}
setDOUT / getDOUT
For controller-level Digital Outputs
{
  "type": "setDOUT",
  "payload": {
    "index": 3,
    "value": false
  }
}

5.5 System Variables
getSystemVar
{
  "type": "getSystemVar",
  "payload": {
    "name": "$SCR.$CYCLETIME"
  }
}
setSystemVar
{
  "type": "setSystemVar",
  "payload": {
    "name": "$MCR.$GENOVERRIDE",
    "value": 50
  }
}

5.6 Robot Configuration Commands
setTool
{
  "type": "setTool",
  "payload": { "toolNumber": 1 }
}
setUserFrame
{
  "type": "setUserFrame",
  "payload": { "userFrame": 0 }
}
setCoordSystem
{
  "type": "setCoord",
  "payload": { "coordSystem": "WORLD" }
}

5.7 Diagnostics & Telemetry
getPowerConsumption
Instantaneous power measurement.
{
  "type": "getPowerConsumption"
}
Result example:
{
  "voltage": 220.5,
  "current": 2.14,
  "power": 472.7
}
getRobotInfo
(e.g., controller info, software version)

5.8 Robot Parameters
Parameters are stored in two places:
* Firestore: /robots/{robotId}/parameters/{parameterId} - definitions/templates
* RTDB: /devices/{deviceId}/robots/{robotId}/parameters - live values

Parameter Definition (Firestore):
{
  "id": "1",
  "name": "FTP Password",
  "defaultValue": "",
  "type": "string",           // string | number | boolean
  "unit": "%",                 // optional
  "category": "Network",       // Network | Motion | System
  "isLocked": false,
  "description": "FTP access password for robot file system",
  "minValue": 0,              // optional, for number type
  "maxValue": 100             // optional, for number type
}

Parameter Value (RTDB):
{
  "value": "",
  "updatedAt": 1732023120,
  "updatedBy": "uid123"
}

updateParameter
{
  "type": "updateParameter",
  "payload": {
    "parameterId": "2",
    "value": 75
  }
}

getParameter
{
  "type": "getParameter",
  "payload": {
    "parameterId": "2"
  }
}

getAllParameters
{
  "type": "getAllParameters"
}
Result: Returns all parameter values from RTDB

6. FTP Command Layer
FTP requests live under:
/devices/{deviceId}/robots/{robotId}/ftp/requests/{reqId}
/devices/{deviceId}/robots/{robotId}/ftp/responses/{reqId}

6.1 FTP Command Types
List Files
{
  "type": "listFiles",
  "payload": {
    "device": "MD",
    "pattern": "*.TP",
    "types": "TP"        // TP | KAREL | ALL
  }
}
Read File
{
  "type": "readFile",
  "payload": {
    "device": "MD",
    "filename": "MAIN001.LS"
  }
}
Write Text File
{
  "type": "writeFile",
  "payload": {
    "device": "MD",
    "filename": "NEWPROG.TP",
    "content": "<...>"
  }
}
Delete File
{
  "type": "deleteFile",
  "payload": {
    "device": "MD",
    "filename": "OLDPROG.TP"
  }
}
Rename File
{
  "type": "renameFile",
  "payload": {
    "oldName": "OLD.TP",
    "newName": "NEW.TP"
  }
}
Create Directory
{
  "type": "createDirectory",
  "payload": { "name": "BACKUPS" }
}
Remove Directory
{
  "type": "removeDirectory",
  "payload": { "name": "OLD_DIR" }
}

7. Alarm System
Live alarms (RTDB)
/devices/{deviceId}/robots/{robotId}/alarms/active/{alarmId}
Alarm history (Firestore)
/robotAlarms/{alarmEventId}

8. End-to-End Flow Example
Mobile App → RTDB
User presses X+:
{
  "type": "jogStart",
  "payload": { "axis": "X", "direction": "+", "speed": 20 }
}
RPi:
* Executes robot.jog_start()
* Sends status:"running"
* When released: jogStop
Mobile App:
* Reads live pose updates every ~200 ms

9. Future Extensions
* Per-robot parameter schemas
* Logging streams
* Multi-user permission levels
* Live video stream metadata channel
