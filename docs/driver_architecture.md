# FANUC Driver Architecture Documentation

## Table of Contents
1. [Overview](#overview)
2. [Server Architecture](#server-architecture)
3. [Socket Communication](#socket-communication)
4. [Command Processing Pipeline](#command-processing-pipeline)
5. [Available Functions](#available-functions)
6. [Motion Execution](#motion-execution)
7. [Jogging System](#jogging-system)
8. [Register and Memory Usage](#register-and-memory-usage)

---

## Overview

The FANUC driver is a TCP/IP-based server that runs on the FANUC robot controller. It enables external applications to control the robot through a simple text-based protocol. The driver is written in KAREL (FANUC's proprietary programming language) and integrates with TP (Teach Pendant) programs for motion execution.

**Key Components:**
- **Server Program** (`FANUC_SVR`): Main TCP server that handles connections and dispatches commands
- **Command Handler** (`fanuc_remote_cmd.kl`): Parses and executes commands
- **Communication Layer** (`fanuc_remote_comm.kl`): Manages TCP socket operations
- **Jogging Module** (`fanuc_remote_jog.kl`): Implements continuous jogging functionality
- **Context Manager** (`fanuc_remote_context.kl`): Manages coordinate frames and tool settings

---

## Server Architecture

### Main Program Structure

The server is implemented in `fanuc_remote_server.kl` as the `FANUC_SVR` program:

```karel
PROGRAM FANUC_SVR
%STACKSIZE = 4000
%NOLOCKGROUP
%NOPAUSE = ERROR + COMMAND + TPENABLE
```

**Key Directives:**
- `%STACKSIZE = 4000`: Allocates 4KB stack for the program
- `%NOLOCKGROUP`: Allows simultaneous execution with other programs
- `%NOPAUSE`: Continues execution even during errors, commands, or when TP is enabled

### Global State Variables

The server maintains global state for:

```karel
VAR
    g_tool_num:         INTEGER      -- Active tool frame number
    g_uframe_num:       INTEGER      -- Active user frame number
    g_coord_type:       INTEGER      -- 0=WORLD, 1=USER, 2=TOOL
    
    jog_active:         ARRAY[6] OF BOOLEAN  -- Active jog flags for X,Y,Z,W,P,R
    jog_dir:            ARRAY[6] OF BOOLEAN  -- Jog direction (TRUE=+, FALSE=-)
    jog_speed:          INTEGER              -- Jog speed percentage (1-100)
    jog_step_lin:       REAL                 -- Linear step size (mm)
    jog_step_rot:       REAL                 -- Rotational step size (deg)
```

### Server Initialization

On startup, the server:
1. Clears the teach pendant screen
2. Initializes global state variables (tool #8, user frame #8, WORLD coordinates)
3. Initializes the jogging module
4. Sets up system variables `$MNUFRAMENUM` and `$MNUTOOLNUM`
5. Configures a condition handler for jog tick timing

### Main Server Loop

The server operates in a two-level loop structure:

```karel
WHILE TRUE DO
    OPEN_COMM(comm_file, SERVER_TAG, PORT_NUMBER)
    keep_conn = TRUE
    
    WHILE keep_conn DO
        cmd = ''
        READ comm_file(cmd::0)            -- Non-blocking read
        status = IO_STATUS(comm_file)
        
        IF (status <> 0) THEN
            keep_conn = FALSE             -- Connection error
        ELSE
            IF STR_LEN(cmd) > 0 THEN
                keep_conn = HANDLE_CMD(cmd, resp)
                WRITE comm_file(resp)
            ENDIF
        ENDIF
        
        -- Handle jog ticks
        IF jog_tick_due AND (NOT jog_in_progr) THEN
            jog_in_progr = TRUE
            JOG_TICK
            jog_in_progr = FALSE
            jog_tick_due = FALSE
        ENDIF
    ENDWHILE
    
    CLOSE_COMM(comm_file, SERVER_TAG)
ENDWHILE
```

**Outer Loop:** Handles connection lifecycle
**Inner Loop:** Processes commands and manages jogging

### Condition Handler for Jogging

The server uses a condition handler for timing jog ticks:

```karel
cont_timer = 0
CONNECT TIMER TO cont_timer

CONDITION[10]:
    WHEN cont_timer >= jog_interval DO
        cont_timer = 0
        jog_tick_due = TRUE
        ENABLE CONDITION[10] 
ENDCONDITION
ENABLE CONDITION[10]
```

This creates a periodic interrupt (default 30ms) for smooth jogging motion.

---

## Socket Communication

### Opening a Connection

The `OPEN_COMM` routine establishes a TCP server socket:

```karel
ROUTINE OPEN_COMM(comm_file: FILE;
                  server_num: INTEGER;
                  port_number: INTEGER)
```

**Process:**
1. Constructs server tag string (e.g., "S8:" for server #8)
2. Sets the server port number in system variable `$HOSTS_CFG[n].$SERVER_PORT`
3. Disconnects any existing connection: `MSG_DISCO(server_tag, status)`
4. Closes any open file handles
5. Sets file attributes: `SET_FILE_ATR(comm_file, ATR_IA)`
6. Initiates connection: `MSG_CONNECT(server_tag, status)`
7. Opens the file for read/write: `OPEN FILE comm_file ('rw', server_tag)`
8. Sends initial response: `"0:success"`

**Default Configuration:**
- Server tag: 8 (tag "S8:")
- Port: 18735
- Protocol: TCP/IP

### Reading Socket Data

The server uses **non-blocking reads** to check for incoming commands:

```karel
cmd = ''
READ comm_file(cmd::0)            -- ::0 = non-blocking
status = IO_STATUS(comm_file)
```

**Non-blocking Read (`::0`):**
- Returns immediately even if no data is available
- `cmd` remains empty if no data received
- Allows the server to handle jog ticks while waiting for commands

**Blocking vs Non-blocking:**
- **Blocking:** `READ comm_file(cmd)` - waits indefinitely
- **Non-blocking:** `READ comm_file(cmd::0)` - returns immediately

### Writing Socket Data

Responses are written synchronously:

```karel
WRITE comm_file(resp)
status = IO_STATUS(comm_file)
IF (status <> 0) THEN
    keep_conn = FALSE
ENDIF
```

### Closing a Connection

The `CLOSE_COMM` routine properly tears down the connection:

```karel
ROUTINE CLOSE_COMM(comm_file: FILE; server_num: INTEGER)
    CLOSE FILE comm_file
    MSG_DISCO(server_tag, status)
END CLOSE_COMM
```

### Error Handling

The server monitors `IO_STATUS` after each read/write:
- **Status 0:** Success
- **Status ≠ 0:** Connection error → close connection

---

## Command Processing Pipeline

### Stage 1: Command Reception

Commands arrive as text strings terminated by newline:

```
"curpos\n"
"movej:0100:0100:050:0:6:+000.000000000:...\n"
"jog_start:X:+:50:1.0\n"
```

### Stage 2: Command Dispatching

The `HANDLE_CMD` routine acts as a dispatcher:

```karel
ROUTINE HANDLE_CMD(cmd: STRING; resp: STRING): BOOLEAN
```

**Returns:**
- `TRUE`: Keep connection open
- `FALSE`: Close connection

**Dispatch Logic:**

```karel
IF cmd = 'exit' THEN
    resp = '0:success'
    RETURN(FALSE)
ENDIF

IF SUB_STR(cmd, 1, 6) = 'curpos' THEN
    resp = GET_CURPOS(cmd)
    RETURN(TRUE)
ENDIF

IF SUB_STR(cmd, 1, 5) = 'movej' THEN
    resp = MOVEJ(cmd)
    RETURN(TRUE)
ENDIF

-- ... more command checks ...
```

The dispatcher uses **prefix matching** with `SUB_STR` to identify commands.

### Stage 3: Command Parsing

Individual command handlers parse their arguments. Two parsing strategies are used:

#### Strategy 1: Colon-Separated Parsing (for simple commands)

```karel
ROUTINE SPLIT_CMD(cmd, sub_cmd, args: STRING)
VAR
    i: INTEGER
BEGIN
    FOR i = 1 TO STR_LEN(cmd) DO
        IF SUB_STR(cmd, i, 1) = ':' THEN
            sub_cmd = SUB_STR(cmd, 1, i-1)
            args = SUB_STR(cmd, i+1, STR_LEN(cmd)-i)
            RETURN
        ENDIF
    ENDFOR
END SPLIT_CMD
```

**Example:**
```
Input:  "set_tool:5"
Output: sub_cmd = "set_tool", args = "5"
```

#### Strategy 2: Position-Based Parsing (for complex commands)

For commands like `movej` with fixed-width fields:

```karel
start = 7  -- Skip "movej:"

-- Parse 4-digit velocity
CNV_STR_INT(SUB_STR(cmd, start, 4), vel_val)
start = start + 4 + 1  -- +1 for delimiter

-- Parse 4-digit acceleration
CNV_STR_INT(SUB_STR(cmd, start, 4), acc_val)
start = start + 4 + 1

-- Parse 3-digit CNT value
CNV_STR_INT(SUB_STR(cmd, start, 3), cnt_val)
start = start + 3 + 1

-- Parse joints (14 chars each)
FOR i=1 TO nj DO
    CNV_STR_REAL(SUB_STR(cmd, start, 14), jval)
    joint_vals[i] = jval
    start = start + 14 + 1
ENDFOR
```

### Stage 4: Argument Validation

Commands validate their inputs:

```karel
-- Check joint position reachability
JOINT2POS(jpos, $UFRAME, $UTOOL, 0, out_pos, wjnt_cfg, ext_ang, status)
IF status <> 0 THEN
    resp = '1:position-is-not-reachable'
    RETURN(resp)
ENDIF

-- Check Cartesian position reachability
CHECK_EPOS((pose), $UFRAME, $UTOOL, status)
IF status <> 0 THEN
    resp = '1:position-is-not-reachable'
    RETURN(resp)
ENDIF
```

### Stage 5: Execution

After validation, the command is executed:
- **Query commands:** Return data immediately
- **Motion commands:** Set up registers and call TP programs
- **Jog commands:** Update jog state variables

### Stage 6: Response Generation

All commands return responses in the format:

```
"<code>:<message>"
```

**Success Response:**
```
"0:success"
"0:x=123.456,y=234.567,z=345.678,..."
"0:OK"
```

**Error Response:**
```
"1:wrong-command"
"1:position-is-not-reachable"
"1:ERR INVALID_AXIS"
```

---

## Available Functions

### Position Query Commands

#### `curpos` - Get Current Cartesian Position

**Command:**
```
curpos
```

**Response:**
```
0:x=<x>,y=<y>,z=<z>,w=<w>,p=<p>,r=<r>
```

**Implementation:**
```karel
ROUTINE GET_CURPOS(cmd: STRING): STRING
    cpos = CURPOS(0, 0)
    -- Format: x, y, z in mm; w, p, r in degrees
    CNV_REAL_STR(cpos.x, 8, 3, out)
    resp = '0:x=' + out
    -- ... repeat for y, z, w, p, r
    RETURN(resp)
END GET_CURPOS
```

**Notes:**
- Returns position in current coordinate system
- Values formatted with 3 decimal places
- Position relative to active UFRAME and UTOOL

---

#### `curjpos` - Get Current Joint Position

**Command:**
```
curjpos
```

**Response:**
```
0:j=<j1>,j=<j2>,j=<j3>,j=<j4>,j=<j5>,j=<j6>[,j=<j7>,j=<j8>,j=<j9>]
```

**Implementation:**
```karel
ROUTINE GET_CURJPOS(cmd: STRING): STRING
    jpos = CURJPOS(0, 0)
    CNV_JPOS_REL(jpos, joint_vals, status)
    
    resp = '0:'
    FOR i=1 TO ARRAY_LEN(joint_vals) DO
        IF UNINIT(joint_vals[i]) THEN
            out='none'
        ELSE
            CNV_REAL_STR(joint_vals[i], 8, 3, out)
        ENDIF
        -- Append to response
    ENDFOR
    RETURN(resp)
END GET_CURJPOS
```

**Notes:**
- Returns joint angles in degrees
- Handles robots with 6-9 axes
- Unused axes return "none"

---

#### `ins_pwr` - Get Instantaneous Power

**Command:**
```
ins_pwr
```

**Response:**
```
0:<power_value>
```

**Implementation:**
```karel
ROUTINE GET_INS_PWR(cmd: STRING): STRING
    GET_VAR(entry, '*SYSTEM*', '$PRO_CFG.$INS_PWR', ins_pwr, status)
    CNV_REAL_STR(ins_pwr, 6, 6, resp)
    resp = '0:' + resp
    RETURN(resp)
END GET_INS_PWR
```

**Notes:**
- Returns instantaneous power consumption in watts
- Queries system variable `$PRO_CFG.$INS_PWR`

---

### Motion Commands

#### `movej` - Move to Joint Position

**Command Format:**
```
movej:<vel>:<acc>:<cnt>:<type>:<nj>:<j1>:<j2>:...:<jn>
```

**Parameters:**
- `<vel>`: 4-digit velocity (0001-0100) representing percentage
- `<acc>`: 4-digit acceleration (0001-0100) representing percentage
- `<cnt>`: 3-digit CNT value (000-100) for motion blending
- `<type>`: 1-digit motion type (0=joint, 1=linear)
- `<nj>`: 1-digit number of joints (6-9)
- `<j1>...<jn>`: 14-character joint angles in degrees (e.g., "+00000012.3456")

**Example:**
```
movej:0050:0100:050:0:6:+00000000.0000:-00000090.0000:+00000000.0000:+00000000.0000:+00000000.0000:+00000000.0000
```

**Response:**
```
0:success
```

**Implementation Flow:**
1. Parse velocity → store in `R[81]`
2. Parse acceleration → store in `R[82]`
3. Parse CNT value → store in `R[83]`
4. Parse joint values → convert to `JOINTPOS6`
5. Validate reachability with forward kinematics (`JOINT2POS`)
6. Store position in `PR[81]`
7. Call TP program:
   - If `type=0`: `CALL_PROGLIN('FANUC_REMOTE_MOVE', ...)`
   - If `type=1`: `CALL_PROGLIN('FANUC_REMOTE_MOVEL', ...)`

**Error Responses:**
- `1:R[81]-was-not-set` - Failed to set velocity register
- `1:R[82]-was-not-set` - Failed to set acceleration register
- `1:R[83]-was-not-set` - Failed to set CNT register
- `1:error-in-joint-values` - Invalid joint angle conversion
- `1:position-is-not-reachable` - Position outside robot workspace
- `1:PR[81]-was-not-set` - Failed to set position register

---

#### `movep` - Move to Cartesian Position

**Command Format:**
```
movep:<vel>:<acc>:<cnt>:<type>:<nv>:<x>:<y>:<z>:<w>:<p>:<r>
```

**Parameters:**
- `<vel>`: 4-digit velocity (0001-0100) for percentage or mm/sec (see type)
- `<acc>`: 4-digit acceleration (0001-0100) representing percentage
- `<cnt>`: 3-digit CNT value (000-100) for motion blending
- `<type>`: 1-digit motion type (0=joint, 1=linear)
- `<nv>`: 1-digit number of values (always 6 for X,Y,Z,W,P,R)
- `<x>,<y>,<z>`: 14-character position in mm
- `<w>,<p>,<r>`: 14-character orientation in degrees

**Example:**
```
movep:0050:0100:050:1:6:+00000500.0000:+00000200.0000:+00000300.0000:+00000000.0000:+00000090.0000:+00000000.0000
```

**Response:**
```
0:success
```

**Implementation Flow:**
1. Parse velocity → store in `R[81]`
2. Parse acceleration → store in `R[82]`
3. Parse CNT value → store in `R[83]`
4. Parse X, Y, Z, W, P, R values → create `XYZWPR` structure
5. Validate reachability (`CHECK_EPOS`)
6. Store position in `PR[81]`
7. Call TP program based on motion type

**Error Responses:**
- Similar to `movej`
- `1:position-is-not-reachable` - Position/orientation not achievable

---

### I/O Commands

#### `setrdo` / `getrdo` - Robot Digital Output

**Set Command:**
```
setrdo:<n>:<value>
```
- `<n>`: Single digit RDO number (1-9)
- `<value>`: "true" or "false"

**Get Command:**
```
getrdo:<n>
```

**Responses:**
```
0:success  (for setrdo)
0:1        (for getrdo, if TRUE)
0:0        (for getrdo, if FALSE)
1:wrong-rdo-value
```

**Implementation:**
```karel
ROUTINE SET_RDO(cmd: STRING): STRING
    CNV_STR_INT(SUB_STR(cmd, 8, 1), rdo_num)
    rdo_val = SUB_STR(cmd, 10, STR_LEN(cmd) - 9)
    
    IF rdo_val = 'true' THEN
        RDO[rdo_num] = TRUE
    ENDIF
    IF rdo_val = 'false' THEN
        RDO[rdo_num] = FALSE
    ENDIF
END SET_RDO
```

---

#### `setdout` / `getdout` - Digital Output

**Set Command:**
```
setdout:<nnnnn>:<value>
```
- `<nnnnn>`: 5-digit DOUT port number with leading zeros (e.g., "00123")
- `<value>`: "true" or "false"

**Get Command:**
```
getdout:<nnnnn>
```

**Responses:**
```
0:success  (for setdout)
0:1        (for getdout, if TRUE)
0:0        (for getdout, if FALSE)
1:wrong-dout-value
```

**Notes:**
- RDO (Robot Digital Output) is typically used for internal robot operations
- DOUT (Digital Output) controls external devices connected to the robot

---

### System Variable Commands

#### `setsysvar` - Set System Variable

**Command Format:**
```
setsysvar:<var_name>:<value>
```
- `<var_name>`: System variable path (e.g., "$SCR.$COND_TIME")
- `<value>`: "T" (TRUE) or "F" (FALSE)

**Example:**
```
setsysvar:$SCR.$COND_TIME:T
```

**Response:**
```
0:success
1:wrong-sys_var-value
```

**Implementation:**
```karel
ROUTINE SET_SYS_VAR(cmd: STRING): STRING
    sys_var = SUB_STR(cmd, 11, (STR_LEN(cmd) - 12))
    sys_val = SUB_STR(cmd, 10 + STR_LEN(sys_var) + 2, 1)
    
    IF sys_val = 'T' THEN
        SET_VAR(entry, '*SYSTEM*', sys_var, TRUE, status)
    ENDIF
    IF sys_val = 'F' THEN
        SET_VAR(entry, '*SYSTEM*', sys_var, FALSE, status)
    ENDIF
END SET_SYS_VAR
```

**Notes:**
- Currently only supports boolean system variables
- Requires knowledge of FANUC system variable names

---

### Frame Selection Commands

#### `set_tool` - Set Active Tool Frame

**Command:**
```
set_tool:<n>
```
- `<n>`: Tool frame number (1-10)

**Response:**
```
0:tool-set-success
1:cannot-set-r84
1:cannot-run-set-utool-tp
```

**Implementation:**
1. Parse tool number
2. Update global state: `g_tool_num = tool_num`
3. Set `R[84]` for TP program
4. Call TP program `SET_UTOOL_TP`
5. Apply kinematic context with `APL_KIN_CTX`

**TP Program Logic (SET_UTOOL_TP.ls):**
```
UTOOL_NUM=R[84:TOOL_NUM]
```

---

#### `set_user` - Set Active User Frame

**Command:**
```
set_user:<n>
```
- `<n>`: User frame number (0-9)

**Response:**
```
0:user-set-success
1:cannot-set-r85
1:cannot-run-set-uframe-tp
```

**Implementation:**
1. Parse user frame number
2. Update global state: `g_uframe_num = user_num`
3. Set `R[85]` for TP program
4. Call TP program `SET_UFRAME_TP`
5. Apply kinematic context

---

#### `set_coord` - Set Coordinate System

**Command:**
```
set_coord:<system>
```
- `<system>`: "WORLD", "USER", or "TOOL"

**Response:**
```
0:coord-set-success
1:invalid-coord-type
```

**Implementation:**
```karel
ROUTINE SET_COORD(cmd: STRING): STRING
    SPLIT_CMD(cmd, sub_cmd, args)
    
    IF args = 'WORLD' THEN
        g_coord_type = 0
    ELSE IF args = 'USER' THEN
        g_coord_type = 1
    ELSE IF args = 'TOOL' THEN
        g_coord_type = 2
    ELSE
        RETURN('1:invalid-coord-type')
    ENDIF
    
    APL_KIN_CTX  -- Apply the new coordinate system
END SET_COORD
```

**Coordinate Systems:**
- **WORLD (0):** Fixed to robot base
- **USER (1):** Relative to active user frame
- **TOOL (2):** Relative to tool center point orientation

---

#### `get_tool`, `get_user`, `get_coord` - Query Frame Settings

**Commands:**
```
get_tool
get_user
get_coord
```

**Responses:**
```
0:<tool_number>        (e.g., "0:5")
0:<user_frame_number>  (e.g., "0:8")
0:<coord_system>       (e.g., "0:WORLD", "0:USER", "0:TOOL")
```

**Implementation:**
```karel
ROUTINE GET_TOOL(cmd: STRING): STRING
    CNV_INT_STR(g_tool_num, 0, 0, val_str)
    resp = '0:' + val_str
    RETURN(resp)
END GET_TOOL
```

---

### Program Execution Command

#### `fanuccall` - Call External TP Program

**Command:**
```
fanuccall:<program_name>
```

**Example:**
```
fanuccall:MY_GRIPPER_PROG
```

**Response:**
```
0:success
```

**Implementation:**
```karel
ROUTINE REMOTECALL(cmd: STRING): STRING
    prg_name = SUB_STR(cmd, 12, STR_LEN(cmd) - 11)
    CALL_PROGLIN(prg_name, 1, prog_index, FALSE)
    resp = '0:success'
    RETURN(resp)
END REMOTECALL
```

**Notes:**
- Can call any TP program loaded on the controller
- Useful for triggering gripper operations, tool changes, etc.
- Program must exist or call will fail

---

### Jogging Commands

#### `jog_start` - Start Continuous Jogging

**Command Format:**
```
jog_start:<AXIS>:<DIR>:[SPEED]:[STEP_LIN]:[STEP_ROT]
```

**Parameters:**
- `<AXIS>`: Axis name (X, Y, Z, W, P, or R)
- `<DIR>`: Direction ("+" or "-")
- `[SPEED]`: Optional speed percentage (1-100), default 75%
- `[STEP_LIN]`: Optional linear step size in mm, default 2.0mm
- `[STEP_ROT]`: Optional rotational step size in degrees, default 1.0°

**Example:**
```
jog_start:X:+:50:1.0
```

**Response:**
```
0:OK
1:ERR BUSY
1:ERR AXIS_ACTIVE
1:ERR INVALID_AXIS
1:ERR INVALID_DIRECTION
1:ERR OUT_OF_RANGE
```

**Implementation Flow:**
1. Parse axis name → convert to index (1-6)
2. Validate axis is not already active (unless multi-axis enabled)
3. Set `jog_active[axis_idx] = TRUE`
4. Set `jog_dir[axis_idx]` to direction
5. Update speed and step parameters if provided
6. On first axis activation:
   - Initialize working position `jog_pr` to current position
   - Set `R[89]=1` to enable jog loop
   - Start TP program `FANUC_REMOTE_JOG`

**Axis Mapping:**
- X → 1, Y → 2, Z → 3 (linear axes)
- W → 4, P → 5, R → 6 (rotational axes)

---

#### `jog_stop` - Stop Jogging Specific Axis

**Command:**
```
jog_stop:<AXIS>
```

**Example:**
```
jog_stop:X
```

**Response:**
```
0:OK
```

**Implementation:**
```karel
ROUTINE JOG_STOP(axis_idx: INTEGER): STRING
    IF jog_active[axis_idx] THEN
        jog_active[axis_idx] = FALSE
        active_axest = active_axest - 1
        
        IF active_axest <= 0 THEN
            active_axest = 0
            SET_INT_REG(89, 0, i)  -- Stop TP loop
        ENDIF
    ENDIF
    RETURN('0:OK')
END JOG_STOP
```

---

#### `jog_stop_all` - Stop All Jogging

**Command:**
```
jog_stop_all
```

**Response:**
```
0:OK
```

**Implementation:**
```karel
ROUTINE JOG_STOP_ALL: STRING
    FOR i = 1 TO 6 DO
        jog_active[i] = FALSE
    ENDFOR
    active_axest = 0
    SET_INT_REG(89, 0, i)  -- Stop TP loop
    RETURN('0:OK')
END JOG_STOP_ALL
```

---

### Connection Control

#### `exit` - Close Connection

**Command:**
```
exit
```

**Response:**
```
0:success
```

**Behavior:**
- Server sends response
- Server closes connection
- Server returns to listening state for new connections
- Existing jog operations are **not** automatically stopped

---

## Motion Execution

### TP Program Architecture

Motion commands don't execute directly from KAREL. Instead, they:
1. Set up register parameters (R[81], R[82], R[83])
2. Store target position/joints in PR[81]
3. Call a TP program to execute the motion

**Why separate TP programs?**
- KAREL cannot directly execute robot motion
- TP programs have native motion instruction support
- Allows motion to run with proper blending and acceleration control

### FANUC_REMOTE_MOVE - Joint Motion

**TP Code:**
```
J PR[81:FANUC_REMOTE_JOINT_POS] R[81:FANUC_REMOTE_VEL]% CNT R[83:FANUC_REMOTE_CNT] ACC R[82]
```

**Explanation:**
- `J`: Joint motion instruction
- `PR[81]`: Position register containing target
- `R[81]%`: Velocity override percentage
- `CNT R[83]`: Corner blending value
- `ACC R[82]`: Acceleration override percentage

**Motion Type:**
- Moves each joint independently
- Fastest path in joint space
- Tool path is not linear in Cartesian space

---

### FANUC_REMOTE_MOVEL - Linear Motion

**TP Code:**
```
L PR[81:FANUC_REMOTE_JOINT_POS] R[81:FANUC_REMOTE_VEL]mm/sec CNT R[83:FANUC_REMOTE_CNT] ACC R[82]
```

**Explanation:**
- `L`: Linear motion instruction
- `R[81]mm/sec`: Linear velocity in mm/second
- Other parameters same as joint motion

**Motion Type:**
- Tool center point follows straight line
- Slower than joint motion
- Predictable tool path in Cartesian space

---

### Motion Parameter Ranges

**Velocity (R[81]):**
- Joint motion: 1-100% of maximum joint speed
- Linear motion: 1-2000 mm/sec typical range

**Acceleration (R[82]):**
- 1-100% of maximum acceleration

**CNT Value (R[83]):**
- 0: Come to complete stop at target (FINE positioning)
- 1-100: Blend through target with radius proportional to value
- Higher values = smoother motion but less accuracy at waypoints

---

## Jogging System

### Architecture Overview

The jogging system simulates iPendant jog functionality through three components:

1. **KAREL State Machine** (`fanuc_remote_jog.kl`)
   - Maintains jog state for each axis
   - Calculates incremental position updates
   - Applies coordinate transformations

2. **Condition Handler** (in `fanuc_remote_server.kl`)
   - Generates periodic "ticks" (default 30ms)
   - Triggers `JOG_TICK` routine

3. **TP Follower Program** (`FANUC_REMOTE_JOG.ls`)
   - Continuously moves to updated position registers
   - Creates smooth motion through position buffering

### Jogging Initialization

```karel
ROUTINE JOG_INIT
    FOR i = 1 TO 6 DO
        jog_active[i] = FALSE
        jog_dir[i] = TRUE
    ENDFOR
    
    jog_speed = 75          -- 75% speed
    jog_step_lin = 2.0      -- 2mm per tick
    jog_step_rot = 1.0      -- 1deg per tick
    jog_interval = 30       -- 30ms between ticks
    multi_axis = FALSE      -- Single axis only
    active_axest = 0
    
    SET_INT_REG(89, 0, i)   -- Disable jog flag
END JOG_INIT
```

### Jog Tick Processing

Every 30ms (configurable), if any axis is active:

```karel
ROUTINE JOG_TICK
    -- 1. Apply kinematic context
    APL_KIN_CTX
    
    -- 2. Calculate delta based on active axes
    delta.x = 0.0
    delta.y = 0.0
    delta.z = 0.0
    delta.w = 0.0
    delta.p = 0.0
    delta.r = 0.0
    
    FOR i = 1 TO 6 DO
        IF jog_active[i] THEN
            SELECT i OF
                CASE (1):  -- X axis
                    IF jog_dir[i] THEN
                        delta.x = jog_step_lin * (jog_speed/100.0)
                    ELSE
                        delta.x = -jog_step_lin * (jog_speed/100.0)
                    ENDIF
                -- ... similar for Y, Z, W, P, R
            ENDSELECT
        ENDIF
    ENDFOR
    
    -- 3. Apply delta in appropriate coordinate system
    SELECT g_coord_type OF
        CASE (0):  APPLY_WINC(delta)      -- WORLD
        CASE (1):  APL_INC_USR(delta)     -- USER
        CASE (2):  APL_INC_TL(delta)      -- TOOL
    ENDSELECT
    
    -- 4. Update position register (double buffering)
    IF pr_toggle THEN
        pr_num = 82
    ELSE
        pr_num = 81
    ENDIF
    SET_POS_REG(pr_num, jog_pr, status)
    pr_toggle = NOT pr_toggle
END JOG_TICK
```

### Coordinate Transformation

#### WORLD Coordinates

```karel
ROUTINE APPLY_WINC(delta: XYZWPR)
    new_pos.x = jog_pr.x + delta.x
    new_pos.y = jog_pr.y + delta.y
    new_pos.z = jog_pr.z + delta.z
    new_pos.w = jog_pr.w + delta.w
    new_pos.p = jog_pr.p + delta.p
    new_pos.r = jog_pr.r + delta.r
    jog_pr = new_pos
END APPLY_WINC
```

Direct addition in world frame.

#### USER Coordinates

```karel
ROUTINE APL_INC_USR(delta: XYZWPR)
    user_world = GET_UFRM_WLD          -- Get user frame transform
    world_delta = TRANS_DELTA(delta, user_world)
    APPLY_WINC(world_delta)
END APL_INC_USR
```

Transforms delta from user frame to world frame before applying.

#### TOOL Coordinates

```karel
ROUTINE APL_INC_TL(delta: XYZWPR)
    tool_world = GET_TFRM_WLD          -- Get tool frame transform
    world_delta = TRANS_DELTA(delta, tool_world)
    APPLY_WINC(world_delta)
END APL_INC_TL
```

Transforms delta from tool frame to world frame before applying.

### TP Follower Program

The TP program runs continuously while jogging:

```
1:  R[89:ENABLE_JOG]=1
2:  LBL[1]
3:  L PR[81] R[81]mm/sec CNT R[83] ACC R[82]
4:  L PR[82] R[81]mm/sec CNT R[83] ACC R[82]
5:  IF (R[89:ENABLE_JOG]=1),JMP LBL[1]
6:  END
```

**Double Buffering:**
- KAREL alternates writing to PR[81] and PR[82]
- TP alternates reading from PR[81] and PR[82]
- Prevents reading a partially-updated position

**Loop Condition:**
- `R[89]=1`: Continue jogging
- `R[89]=0`: Exit loop and stop

---

## Register and Memory Usage

### Integer Registers

| Register | Name | Purpose |
|----------|------|---------|
| R[81] | FANUC_REMOTE_VEL | Motion velocity (% or mm/sec) |
| R[82] | FANUC_REMOTE_ACC | Motion acceleration (%) |
| R[83] | FANUC_REMOTE_CNT | Motion CNT blending value |
| R[84] | TOOL_NUM | Temporary storage for tool number |
| R[85] | UFRAME_NUM | Temporary storage for user frame number |
| R[89] | ENABLE_JOG | Jog loop enable flag (1=run, 0=stop) |

### Position Registers

| Register | Name | Purpose |
|----------|------|---------|
| PR[81] | FANUC_REMOTE_POS_A | Motion target / Jog buffer A |
| PR[82] | FANUC_REMOTE_POS_B | Jog buffer B (double buffering) |

### System Variables

| Variable | Purpose |
|----------|---------|
| `$HOSTS_CFG[n].$SERVER_PORT` | TCP server port configuration |
| `$MNUFRAMENUM[1]` | Active user frame number |
| `$MNUTOOLNUM[1]` | Active tool number |
| `$GROUP[1].$UFRAME` | User frame transformation matrix |
| `$GROUP[1].$UTOOL` | Tool frame transformation matrix |
| `$MNCOORDSYS[1]` | Active coordinate system (0=WORLD, 1=USER, 2=TOOL) |
| `$PRO_CFG.$INS_PWR` | Instantaneous power consumption |
| `$SCR.$COND_TIME` | Condition handler tick interval (ms) |

### Global Variables

| Variable | Type | Purpose |
|----------|------|---------|
| `g_tool_num` | INTEGER | Currently selected tool frame number |
| `g_uframe_num` | INTEGER | Currently selected user frame number |
| `g_coord_type` | INTEGER | Active coordinate system (0/1/2) |
| `jog_active[6]` | BOOLEAN ARRAY | Jog active flags for X,Y,Z,W,P,R |
| `jog_dir[6]` | BOOLEAN ARRAY | Jog directions (TRUE=+, FALSE=-) |
| `jog_speed` | INTEGER | Jog speed percentage (1-100) |
| `jog_step_lin` | REAL | Linear jog step size (mm) |
| `jog_step_rot` | REAL | Rotational jog step size (deg) |
| `jog_interval` | INTEGER | Time between jog ticks (ms) |
| `jog_pr` | XYZWPR | Working position for jogging |
| `multi_axis` | BOOLEAN | Allow simultaneous multi-axis jog |
| `active_axest` | INTEGER | Count of currently active jog axes |
| `pr_toggle` | BOOLEAN | Position register toggle flag |

---

## Summary

The FANUC driver provides a comprehensive TCP/IP interface for robot control with:

- **Simple text-based protocol** for easy integration
- **Non-blocking socket operations** for responsive command processing
- **Comprehensive command set** covering motion, I/O, queries, and jogging
- **Robust error handling** with clear error messages
- **Flexible coordinate system support** (WORLD/USER/TOOL)
- **Smooth continuous jogging** similar to iPendant operation
- **Clean separation** between KAREL logic and TP motion execution

The architecture ensures safe, predictable robot control while maintaining compatibility with standard FANUC programming paradigms.

