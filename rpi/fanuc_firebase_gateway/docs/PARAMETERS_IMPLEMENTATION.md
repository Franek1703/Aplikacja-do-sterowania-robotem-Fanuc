# Robot Parameters Implementation

## Overview

Robot parameters are now fully implemented in the FANUC Firebase Gateway. Parameters are stored in two places:

1. **Firestore** (`/robots/{robotId}/parameters/{parameterId}`) - Parameter definitions/templates
2. **Realtime Database** (`/devices/{deviceId}/robots/{robotId}/parameters`) - Live parameter values

## Architecture

### Components

1. **`parameter_manager.py`** - Core parameter management
   - Loads parameter definitions from Firestore
   - Initializes RTDB with default values
   - Handles parameter updates with validation
   - Provides get/getAll operations

2. **`models.py`** - Data models
   - `ParameterDefinition` - Firestore parameter schema
   - `ParameterValue` - RTDB parameter value
   - `ParameterUpdate` - Update command payload

3. **`dispatcher.py`** - Command handlers
   - `updateParameter` - Update a parameter value
   - `getParameter` - Get a single parameter
   - `getAllParameters` - Get all parameters

4. **`robot_session_manager.py`** - Session integration
   - Creates `ParameterManager` on robot connection
   - Loads definitions and initializes RTDB
   - Passes to `CommandDispatcher`

## Parameter Types

### Firestore Parameter Definition

```json
{
  "id": "2",
  "name": "Override Speed",
  "defaultValue": 100,
  "type": "number",
  "unit": "%",
  "category": "Motion",
  "isLocked": false,
  "description": "Global speed override percentage",
  "minValue": 0,
  "maxValue": 100
}
```

**Fields:**
- `id` (string) - Unique parameter identifier
- `name` (string) - Human-readable name
- `defaultValue` (any) - Default value
- `type` (string) - "string", "number", or "boolean"
- `category` (string) - "Network", "Motion", or "System"
- `isLocked` (boolean) - If true, parameter cannot be changed
- `description` (string) - Parameter description
- `unit` (string, optional) - Unit of measurement (e.g., "%", "mm/s")
- `minValue` (number, optional) - Minimum value (for number type)
- `maxValue` (number, optional) - Maximum value (for number type)

### RTDB Parameter Value

```json
{
  "value": 100,
  "updatedAt": 1732023120000,
  "updatedBy": "uid123"
}
```

**Fields:**
- `value` (any) - Current parameter value
- `updatedAt` (number) - Unix timestamp in milliseconds
- `updatedBy` (string) - User ID who last updated

## Commands

### 1. Update Parameter

**Command:**
```json
{
  "type": "updateParameter",
  "status": "pending",
  "payload": {
    "parameterId": "2",
    "value": 75,
    "updatedBy": "uid123"
  }
}
```

**Validation:**
- Checks if parameter exists
- Validates type (string/number/boolean)
- Checks if parameter is locked
- Validates range (min/max for numbers)

**Response:**
```json
{
  "code": 0,
  "message": "Parameter 2 updated successfully",
  "data": {
    "parameterId": "2",
    "value": 75
  }
}
```

### 2. Get Parameter

**Command:**
```json
{
  "type": "getParameter",
  "payload": {
    "parameterId": "2"
  }
}
```

**Response:**
```json
{
  "code": 0,
  "message": "Parameter 2 retrieved",
  "data": {
    "parameterId": "2",
    "value": 75,
    "updatedAt": 1732023120000,
    "updatedBy": "uid123"
  }
}
```

### 3. Get All Parameters

**Command:**
```json
{
  "type": "getAllParameters",
  "payload": {}
}
```

**Response:**
```json
{
  "code": 0,
  "message": "Retrieved 4 parameters",
  "data": {
    "parameters": {
      "1": {
        "value": "",
        "updatedAt": 1732023120000,
        "updatedBy": "system"
      },
      "2": {
        "value": 75,
        "updatedAt": 1732023120000,
        "updatedBy": "uid123"
      },
      ...
    }
  }
}
```

## Initialization Flow

1. **Robot Session Start:**
   - `RobotSessionManager` creates `ParameterManager`
   - Loads parameter definitions from Firestore
   - Checks RTDB for existing parameters
   - Initializes missing parameters with default values

2. **Parameter Manager:**
   - Caches definitions in memory
   - Validates all updates against definitions
   - Updates RTDB with new values
   - Tracks who updated and when

3. **Command Dispatcher:**
   - Receives parameter commands from RTDB
   - Routes to `ParameterManager`
   - Returns results to command channel

## Testing

### Setup Test Parameters

```bash
python3 test_parameters.py
```

This will:
1. Create 4 test parameter definitions in Firestore
2. Test `ParameterManager` functionality
3. Test parameter commands (if gateway is running)

### Manual Testing

1. **Create parameter definitions in Firestore:**
   ```
   /robots/{robotId}/parameters/1
   /robots/{robotId}/parameters/2
   /robots/{robotId}/parameters/3
   /robots/{robotId}/parameters/4
   ```

2. **Start the gateway:**
   ```bash
   python3 -m main
   ```

3. **Send update command:**
   ```
   /devices/{deviceId}/robots/{robotId}/commands/{commandId}
   ```

4. **Check RTDB for updated values:**
   ```
   /devices/{deviceId}/robots/{robotId}/parameters
   ```

## Example Parameters

### Network Category

**1. FTP Password**
- Type: string
- Default: ""
- Description: FTP access password

**4. Controller IP**
- Type: string
- Default: "192.168.1.100"
- Description: Controller IP address

### Motion Category

**2. Override Speed**
- Type: number
- Default: 100
- Unit: %
- Range: 0-100
- Description: Global speed override

### System Category

**3. Auto Backup**
- Type: boolean
- Default: true
- Description: Automatic program backup

## Error Handling

### Validation Errors

- **Locked Parameter:** `"Parameter X is locked"`
- **Type Mismatch:** `"Expected number, got string"`
- **Out of Range:** `"Value must be >= 0"`
- **Not Found:** `"Parameter X not found"`

### Update Failures

- Returns `code: 1` with error message
- Original value remains unchanged
- Error logged to gateway logs

## Integration with Mobile App

The mobile app should:

1. **Load Definitions:**
   - Read from Firestore `/robots/{robotId}/parameters`
   - Display parameter UI based on type and category

2. **Display Current Values:**
   - Listen to RTDB `/devices/{deviceId}/robots/{robotId}/parameters`
   - Show real-time updates

3. **Update Parameters:**
   - Send `updateParameter` command to RTDB
   - Wait for command completion
   - Show success/error message

4. **Handle Locked Parameters:**
   - Disable UI for locked parameters
   - Show lock icon
   - Display error if user tries to update

## Security Rules

### Firestore

```javascript
match /robots/{robotId}/parameters/{parameterId} {
  // Allow authenticated users to read
  allow read: if request.auth != null;
  
  // Only admins can modify definitions
  allow write: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

### Realtime Database

```json
{
  "parameters": {
    ".read": "auth != null",
    ".write": "auth != null",
    "$parameterId": {
      ".validate": "newData.hasChildren(['value', 'updatedAt', 'updatedBy'])"
    }
  }
}
```

## Future Enhancements

- [ ] Parameter history/audit log
- [ ] Batch parameter updates
- [ ] Parameter groups/presets
- [ ] Parameter import/export
- [ ] Parameter change notifications
- [ ] Conditional parameters (depends on other params)
- [ ] Parameter templates by robot model

