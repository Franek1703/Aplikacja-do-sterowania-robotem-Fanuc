# Firebase Parameters Setup Guide

This guide explains what you need to add to Firebase to support Robot Parameters functionality.

## Overview

Robot Parameters are stored in two places:
1. **Firestore** - Parameter definitions/templates (what parameters exist, their types, defaults)
2. **Realtime Database (RTDB)** - Current live parameter values (what the robot is actually using)

## 1. Firestore Setup

### Collection Structure

Create a subcollection under each robot document:

**Path:** `/robots/{robotId}/parameters/{parameterId}`

### Required Parameters

For each robot, create the following parameter documents:

#### Network Category

**Parameter ID: `1` - FTP Password**
```json
{
  "id": "1",
  "name": "FTP Password",
  "defaultValue": "",
  "type": "string",
  "category": "Network",
  "isLocked": false,
  "description": "FTP access password for robot file system"
}
```

**Parameter ID: `4` - Controller IP**
```json
{
  "id": "4",
  "name": "Controller IP",
  "defaultValue": "192.168.1.100",
  "type": "string",
  "category": "Network",
  "isLocked": false,
  "description": "Controller network IP address"
}
```

#### Motion Category

**Parameter ID: `2` - Override Speed**
```json
{
  "id": "2",
  "name": "Override Speed",
  "defaultValue": 100,
  "type": "number",
  "unit": "%",
  "category": "Motion",
  "isLocked": false,
  "description": "Global speed override percentage"
}
```

#### System Category

**Parameter ID: `3` - Auto Backup**
```json
{
  "id": "3",
  "name": "Auto Backup",
  "defaultValue": true,
  "type": "boolean",
  "category": "System",
  "isLocked": false,
  "description": "Automatic backup of programs"
}
```

### How to Add in Firebase Console

1. Go to **Firestore Database** in Firebase Console
2. Navigate to `/robots/{yourRobotId}/parameters`
3. Click **Start collection** (if parameters subcollection doesn't exist)
4. For each parameter:
   - Click **Add document**
   - Use the parameter ID as the document ID (e.g., `1`, `2`, `3`, `4`)
   - Add all fields from the JSON above

### Alternative: Use Firebase Admin SDK or Script

You can also create these programmatically using the Firebase Admin SDK or a setup script.

## 2. Realtime Database Setup

### Structure

**Path:** `/devices/{deviceId}/robots/{robotId}/parameters`

### Initial Values

The gateway should initialize these values when a robot is first connected. You can also set them manually:

```json
{
  "parameters": {
    "1": {
      "value": "",
      "updatedAt": 1732023120,
      "updatedBy": "system"
    },
    "2": {
      "value": 100,
      "updatedAt": 1732023115,
      "updatedBy": "system"
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
```

### How to Add in Firebase Console

1. Go to **Realtime Database** in Firebase Console
2. Navigate to `/devices/{deviceId}/robots/{robotId}`
3. Add a `parameters` node
4. Add each parameter ID as a child with its value structure

**Note:** The gateway should automatically initialize these when a robot is selected. Manual setup is only needed for testing.

## 3. Security Rules

### Firestore Rules

Add rules to allow reading parameter definitions:

```javascript
match /robots/{robotId}/parameters/{parameterId} {
  // Allow authenticated users to read parameter definitions
  allow read: if request.auth != null;
  
  // Only admins can modify parameter definitions
  allow write: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

### Realtime Database Rules

Add rules for parameter values:

```json
{
  "rules": {
    "devices": {
      "$deviceId": {
        "robots": {
          "$robotId": {
            "parameters": {
              // Allow authenticated users to read current values
              ".read": "auth != null",
              
              // Allow authenticated users to update values (gateway and app)
              ".write": "auth != null",
              
              "$parameterId": {
                // Validate parameter updates
                ".validate": "newData.hasChildren(['value', 'updatedAt'])"
              }
            }
          }
        }
      }
    }
  }
}
```

## 4. Gateway Implementation Notes

The Raspberry Pi gateway should:

1. **On robot connection:**
   - Read parameter definitions from Firestore `/robots/{robotId}/parameters`
   - Initialize RTDB `/devices/{deviceId}/robots/{robotId}/parameters` with default values if not present
   - Read current parameter values from the robot (if supported) and sync to RTDB

2. **On parameter update command:**
   - Receive command from RTDB `/devices/{deviceId}/robots/{robotId}/commands/{commandId}` with `type: "updateParameter"`
   - Update the robot parameter via RobotAdapter
   - Update RTDB with new value
   - Mark command as completed

3. **Periodically:**
   - Read current parameter values from robot
   - Update RTDB if values have changed

## 5. Testing Checklist

- [ ] Created parameter definitions in Firestore for at least one robot
- [ ] Verified parameter definitions are readable by authenticated users
- [ ] Initialized parameter values in RTDB (or verified gateway does this)
- [ ] Tested reading parameters in the mobile app
- [ ] Tested updating a parameter (sends command, gateway processes it, RTDB updates)
- [ ] Verified locked parameters cannot be changed
- [ ] Verified parameter validation (min/max values, types)

## Summary

**What to add in Firebase:**

1. **Firestore:** Parameter definitions subcollection at `/robots/{robotId}/parameters/{parameterId}` for each robot
2. **RTDB:** Parameter values node at `/devices/{deviceId}/robots/{robotId}/parameters` (can be auto-initialized by gateway)
3. **Security Rules:** Update Firestore and RTDB rules to allow appropriate access

The gateway should handle most of the RTDB initialization automatically when a robot is connected.

