````markdown
# Firebase Architecture & Data Flow for the FANUC Remote Control Platform

This document describes the **complete Firebase logic** for the FANUC remote control system:

- What is stored in **Cloud Firestore**
- What is stored in **Realtime Database (RTDB)**
- How the **Raspberry Pi gateway** and **mobile app** interact with both
- How devices and robots are **registered** and **configured**

---

## 1. High-Level Architecture

### 1.1 Components

- **Mobile App (Flutter)**
  - Authenticates the user
  - Reads configuration and metadata from **Firestore**
  - Reads/updates live status, commands, FTP operations via **RTDB**

- **Raspberry Pi Gateway (RPi)**
  - Runs Python gateway + `Robot` / `RobotFTP` integration
  - Authenticates with Firebase via **Service Account (Admin SDK)**
  - Auto-registers itself as a **device** in Firestore + RTDB
  - Subscribes to RTDB for commands / FTP requests
  - Publishes live robot status and alarm info to RTDB

- **FANUC Robot**
  - Controlled via TCP / KAREL server + FTP access
  - Interfaced through the Python `Robot` and `RobotFTP` classes

---

## 2. Firestore – Persistent Data

Firestore is used for **persistent configuration**, metadata, and relationships between users, devices, and robots.

### 2.1 Users

**Collection:** `/users/{uid}`

Purpose: store basic user profile and role.

Example:

```jsonc
{
  "email": "engineer@company.com",
  "displayName": "John Engineer",
  "role": "engineer",        // "admin" | "engineer" | "viewer"
  "createdAt": "<timestamp>",
  "lastLoginAt": "<timestamp>",
  "company": "ACME Robotics"
}
````

Mobile app:

* Reads the current user document after login.
* Uses the `role` and `members` lists on devices for authorization.

---

### 2.2 Devices (Gateways / Raspberry Pis)

**Collection:** `/devices/{deviceId}`

Each document represents **one RPi gateway**.

**Device ID**:

* Derived deterministically from the RPi, e.g.:

  * Normalized MAC address (e.g. `rpi_mac_001122aabbcc`)
* Used **both** in Firestore and RTDB to refer to the same physical device.

Example:

```jsonc
{
  "name": "RPi Gateway 00:11:22:AA:BB:CC",
  "description": "Auto-registered device",
  "ownerUid": "uid123",           // optional; set later
  "members": ["uid123", "uid456"],
  "online": true,
  "lastSeen": "<timestamp>",
  "robotCount": 0,
  "createdAt": "<timestamp>"
}
```

**Gateway logic on startup:**

1. Compute `deviceId` from MAC.
2. Check if `/devices/{deviceId}` exists.
3. If not:

   * Create a new Firestore document with default values (auto-registration).
4. Periodically update:

   * `online: true`
   * `lastSeen: <server timestamp>`

Mobile app:

* Queries `devices` where `members` contains current `uid`.
* Displays list of gateways for the logged-in user.

---

### 2.3 Robots

**Collection:** `/robots/{robotId}`

Each document represents a **logical robot instance** that can be controlled via a gateway.

Example:

```jsonc
{
  "deviceId": "rpi_mac_001122aabbcc",
  "name": "FANUC R-2000iC/165F",
  "series": "R-2000iC Series",
  "model": "R-2000iC/165F",
  "controller": "R-30iB",
  "ipAddress": "192.168.0.20",
  "tcpPort": 18735,
  "ftpUser": "anonymous",
  "ftpPassword": "",
  "simulation": false,             // true = use simulated adapter
  "isOnline": true,                // mirrored from RTDB
  "lastSeen": "<timestamp>",
  "createdAt": "<timestamp>"
}
```

**Key points:**

* All **robot connection settings** come from this document:

  * `ipAddress`, `tcpPort`
  * `ftpUser`, `ftpPassword`
  * `simulation`
* The RPi never reads robot IP/port from environment variables.
* The app binds a robot to a device via `deviceId`.

Mobile app:

* For a selected device, queries `robots` with `deviceId == selectedDeviceId`.
* Shows tiles for each robot.

Gateway:

* When a robot is selected (see RTDB section), loads this document and configures `RobotAdapter`.

---

### 2.4 Robot Parameters (Configuration Templates)

**Collection:** `/robots/{robotId}/parameters/{parameterId}`

Purpose: store **parameter definitions and default values** for each robot. These are templates that define what parameters are available and their default values.

**Note:** Current parameter values are stored in RTDB (see section 3.5). This Firestore collection stores the parameter schema/definitions.

Example:

```jsonc
{
  "id": "1",
  "name": "Override Speed",
  "defaultValue": 100,
  "type": "number",              // "number" | "boolean" | "string"
  "unit": "%",
  "category": "Motion",          // "Motion" | "Safety" | "Configuration" | "System" | "Network"
  "isLocked": false,             // true = cannot be changed by user
  "description": "Global speed override percentage",
  "minValue": 0,                 // optional, for number type
  "maxValue": 200,               // optional, for number type
  "allowedValues": null           // optional, for string type (array of allowed values)
}
```

**Default Parameters:**

The following parameters should be created for each robot:

**Network Category:**
- `FTP Password` (string, default: "", parameter ID: "1")
- `Controller IP` (string, default: "192.168.1.100", parameter ID: "4")

**Motion Category:**
- `Override Speed` (number, %, default: 100, range: 0-200, parameter ID: "2")

**System Category:**
- `Auto Backup` (boolean, default: true, parameter ID: "3")

Mobile app:

* Reads parameter definitions from Firestore when loading the parameters view.
* Uses these to display the parameter UI with proper types, units, and validation.

Gateway:

* Can read parameter definitions to understand available parameters.
* Can validate parameter updates against definitions (min/max, allowed values).

---

### 2.5 Robot Alarms History (Optional)

**Collection:** `/robotAlarms/{alarmEventId}`

Purpose: store **historical** alarm entries for reporting.

Example:

```jsonc
{
  "robotId": "robot_001",
  "deviceId": "rpi_mac_001122aabbcc",
  "code": "SRVO-050",
  "severity": "ERROR",          // ERROR | WARNING | INFO
  "title": "Collision detected on J3",
  "description": "Excessive force detected...",
  "timestamp": "<timestamp>",
  "clearedAt": null
}
```

Gateway:

* When reading current alarms from robot, can:

  * Update **RTDB active alarms**, and
  * Append events to Firestore history.

---

## 3. Realtime Database – Live Data & Commands

RTDB is used for all **live** communication and state:

* Device online status
* Robot status (pose, joints, mode)
* Alarms (active)
* Commands queue
* FTP requests/responses
* Currently selected robot for a given device

Root structure:

```text
/devices/{deviceId}/...
```

---

### 3.1 Device Node in RTDB

**Path:** `/devices/{deviceId}`

Created by the gateway on startup, similar to Firestore.

Example structure:

```jsonc
{
  "status": {
    "online": true,
    "lastSeen": 1732023100
  },
  "info": {
    "name": "RPi Gateway 00:11:22:AA:BB:CC",
    "description": "Auto-registered device",
    "deviceId": "rpi_mac_001122aabbcc"
  },
  "selectedRobotId": "robot_001",    // chosen by mobile app
  "robots": { ... },                 // live data per-robot
  "logs": { ... }                    // optional future extension
}
```

Gateway:

* On boot:

  * Ensures `/devices/{deviceId}` exists.
  * Sets initial `status.online = true`, `status.lastSeen = now`.
* Periodically updates `status.lastSeen`.

Mobile app:

* Uses `status.online` for live indicator (green/red).

---

### 3.2 Dynamic Robot Selection

**Path:** `/devices/{deviceId}/selectedRobotId`

* Set by the **mobile app** when the user selects a robot on the UI.
* Cleared (or changed) when the user disconnects or selects another robot.

**Gateway behavior:**

1. Subscribes to `selectedRobotId` for its own `deviceId`.
2. When it changes:

   * If `null` → stop all robot-related tasks (status publisher, command listeners).
   * If new `robotId`:

     1. Read Firestore `/robots/{robotId}`.
     2. Build appropriate `RobotAdapter`:

        * `simulation == true` → use `SimulatedRobotAdapter`.
        * else → use `RealRobotAdapter` with `ipAddress`, `tcpPort`, `ftpUser`, `ftpPassword`.
     3. Start:

        * Status publisher loop.
        * Command listener.
        * FTP request listener.

This enables **multi-robot** support with dynamic runtime switching.

---

### 3.3 Live Robot Data

For each robot, live data is stored under:

**Path:** `/devices/{deviceId}/robots/{robotId}`

Example:

```jsonc
{
  "status": {
    "online": true,
    "mode": "AUTO",      // T1, T2, MANUAL, AUTO
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
  }
}
```

Gateway (StatusPublisher):

* At a configurable interval (e.g. 200 ms):

  * Reads actual robot state from `RobotAdapter`.
  * Writes `status`, `currentPose`, `currentJoints`, `config`.

Mobile app:

* Subscribes to these paths:

  * For real-time control UI, jog view, pose, and joint display.

---

### 3.4 Active Alarms in RTDB

**Path:** `/devices/{deviceId}/robots/{robotId}/alarms/active/{alarmId}`

Example:

```jsonc
{
  "code": "SRVO-050",
  "severity": "ERROR",
  "title": "Collision detected on J3",
  "description": "Excessive force detected during motion.",
  "timestamp": 1732022800,
  "source": "robot"
}
```

Gateway:

* Periodically or on change:

  * Reads current alarm list from the robot.
  * Synchronizes `alarms/active` (add/update/remove).
* Optionally also appends history to Firestore `/robotAlarms`.

Mobile app:

* Subscribes to `alarms/active` to display current robot alarms.

---

### 3.5 Robot Parameters (Live Values)

**Path:** `/devices/{deviceId}/robots/{robotId}/parameters/{parameterId}`

Purpose: store **current parameter values** that can be updated in real-time.

**Note:** Parameter definitions are in Firestore (see section 2.4). This RTDB path stores the actual current values.

Example:

```jsonc
{
  "id": "1",
  "value": 100,                  // current value (can be number, boolean, or string)
  "updatedAt": 1732023120,
  "updatedBy": "uid123"
}
```

**Alternative structure (all parameters in one node):**

```jsonc
{
  "parameters": {
    "1": { "value": "", "updatedAt": 1732023120 },
    "2": { "value": 100, "updatedAt": 1732023115 },
    "3": { "value": true, "updatedAt": 1732023100 },
    "4": { "value": "192.168.1.100", "updatedAt": 1732023090 }
  }
}
```

**Gateway behavior:**

* On robot connection:
  * Reads parameter definitions from Firestore `/robots/{robotId}/parameters`.
  * Initializes RTDB parameters with default values if not present.
* Periodically:
  * Reads current parameter values from robot (if supported).
  * Updates RTDB with actual robot values.
* On parameter update command:
  * Updates robot parameter via RobotAdapter.
  * Updates RTDB with new value.

**Mobile app:**

* Subscribes to `/devices/{deviceId}/robots/{robotId}/parameters` for real-time updates.
* Sends `updateParameter` commands to change parameter values.
* Displays parameters grouped by category from Firestore definitions.

**Parameter Update Command:**

When a user updates a parameter, the app sends a command:

**Path:** `/devices/{deviceId}/robots/{robotId}/commands/{commandId}`

```jsonc
{
  "type": "updateParameter",
  "status": "pending",
  "createdAt": 1732023200,
  "createdBy": "uid123",
  "payload": {
    "parameterId": "1",
    "value": 150
  },
  "result": {
    "code": null,
    "message": null,
    "data": null,
    "completedAt": null
  }
}
```

Gateway processes this command and updates both the robot and RTDB.

---

## 4. Commands in RTDB

Commands implement the **request/response** pattern between mobile app and gateway.

### 4.1 Robot Command Channel

**Path:**
`/devices/{deviceId}/robots/{robotId}/commands/{commandId}`

Each command document:

```jsonc
{
  "type": "move",                 // command type (see protocol spec)
  "status": "pending",            // pending | running | success | error
  "createdAt": 1732023170,
  "createdBy": "uid123",
  "payload": { /* type-specific */ },
  "result": {
    "code": null,                 // e.g. 0 = success, 1 = error
    "message": null,
    "data": null,                 // optional: extra info
    "completedAt": null
  }
}
```

**Gateway behavior (CommandListener + Dispatcher):**

1. Listens for new commands with `status == "pending"`.
2. For each such command:

   * Set `status = "running"`.
   * Dispatch based on `type` to appropriate `RobotAdapter` / FTP bridge method.
   * On completion:

     * Update `status = "success"` or `"error"`.
     * Fill in `result.code`, `result.message`, optional `result.data`.
     * Set `result.completedAt`.

Mobile app:

* Writes new command documents (unique `commandId`).
* Subscribes to that command’s path to observe execution status and result.

---

### 4.2 FTP Commands

FTP operations use a similar pattern but in a separate subtree.

**Requests path:**
`/devices/{deviceId}/robots/{robotId}/ftp/requests/{requestId}`

**Responses path:**
`/devices/{deviceId}/robots/{robotId}/ftp/responses/{requestId}`

**Request example:**

```jsonc
{
  "type": "listFiles",
  "status": "pending",
  "createdAt": 1732023200,
  "createdBy": "uid123",
  "payload": {
    "device": "MD",
    "pattern": "*.TP",
    "types": "TP"
  }
}
```

**Response example:**

```jsonc
{
  "status": "success",
  "completedAt": 1732023201,
  "files": [
    { "name": "MAIN001.TP", "size": 2048, "lastModified": "2025-11-01T12:00:00Z" },
    { "name": "PICK01.TP", "size": 1024, "lastModified": "2025-11-02T09:13:00Z" }
  ],
  "error": null
}
```

Gateway (FTP bridge):

* Listens on `ftp/requests` for `status == "pending"`.
* Executes FTP calls using `RobotFTP`.
* Writes result under `ftp/responses/{requestId}`.

Mobile app:

* Creates request.
* Subscribes to matching response.

---

## 5. Summary: Firestore vs Realtime Database

### 5.1 Firestore (Persistent / Configuration)

* `/users/{uid}`

  * User profile, roles.
* `/devices/{deviceId}`

  * Static device metadata, online flag, lastSeen.
* `/robots/{robotId}`

  * Robot configuration: IP, ports, FTP credentials, model, simulation mode.
* `/robots/{robotId}/parameters/{parameterId}`

  * Parameter definitions and default values (templates).
* `/robotAlarms/{alarmEventId}` (optional)

  * Historical alarm log.

**Usage:**

* Configuration, metadata, and structure of the system.
* Discovering available devices and robots.
* Long-term history & audit.

---

### 5.2 Realtime Database (Live / Dynamic)

* `/devices/{deviceId}`

  * `status.online`, `status.lastSeen`
  * `info` (name, description, deviceId)
  * `selectedRobotId` – chosen by the app, drives which robot session is active.
* `/devices/{deviceId}/robots/{robotId}`

  * `status` (mode, eStop, alarmCount)
  * `currentPose`
  * `currentJoints`
  * `config` (active tool, user frame, coord system, active program)
* `/devices/{deviceId}/robots/{robotId}/alarms/active`

  * Active alarm list.
* `/devices/{deviceId}/robots/{robotId}/parameters`

  * Current parameter values (live, updatable).
* `/devices/{deviceId}/robots/{robotId}/commands`

  * Robot command queue with status & result.
* `/devices/{deviceId}/robots/{robotId}/ftp/requests`
* `/devices/{deviceId}/robots/{robotId}/ftp/responses`

  * FTP operations.

**Usage:**

* Real-time UI updates.
* Low-latency command execution.
* Bi-directional communication between app and RPi gateway.
* Separation of:

  * Persistent configuration (Firestore),
  * Live state & commands (RTDB).
