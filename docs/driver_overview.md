# FANUC Driver System Overview

## Quick Navigation

- **New to the driver?** Start with [Driver Architecture](driver_architecture.md) for in-depth technical details
- **Looking for commands?** Check the [Command Reference](command_reference.md)
- **Need general overview?** See [System Architecture](architecture.md)
- **Want to get started?** View [Getting Started Guide](index.md)

---

## System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                      FANUC Robot Controller                      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              FANUC_SVR (Main Server Program)               │ │
│  │                                                              │ │
│  │  • Listens on TCP port 18735                               │ │
│  │  • Non-blocking socket read loop                           │ │
│  │  • Dispatches commands to handlers                         │ │
│  │  • Manages jog tick timing (30ms intervals)                │ │
│  │                                                              │ │
│  │  Global State:                                              │ │
│  │    - Tool frame number (g_tool_num)                        │ │
│  │    - User frame number (g_uframe_num)                      │ │
│  │    - Coordinate system (g_coord_type: WORLD/USER/TOOL)     │ │
│  │    - Jogging state (active axes, directions, speed, step)  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↕                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │            Command Processing Pipeline                      │ │
│  │                                                              │ │
│  │  1. OPEN_COMM / CLOSE_COMM  ← Socket management            │ │
│  │  2. HANDLE_CMD              ← Command dispatcher           │ │
│  │  3. Specific handlers:                                      │ │
│  │     • MOVEJ / MOVEP         ← Motion commands              │ │
│  │     • GET_CURPOS / GET_CURJPOS ← Position queries          │ │
│  │     • SET_TOOL / SET_USER / SET_COORD ← Frame config       │ │
│  │     • JOG_START / JOG_STOP  ← Jogging control              │ │
│  │     • SET_RDO / GET_RDO     ← I/O operations               │ │
│  │  4. APL_KIN_CTX             ← Apply coordinate context     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↕                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │            Register and Position Storage                    │ │
│  │                                                              │ │
│  │  R[81] ← Velocity        PR[81] ← Target Position (A)      │ │
│  │  R[82] ← Acceleration    PR[82] ← Target Position (B)      │ │
│  │  R[83] ← CNT Blending    PR[...] ← Other positions         │ │
│  │  R[84] ← Tool Number                                        │ │
│  │  R[85] ← User Frame Number                                  │ │
│  │  R[89] ← Jog Enable Flag                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↕                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │            TP Programs (Teach Pendant)                      │ │
│  │                                                              │ │
│  │  FANUC_REMOTE_MOVE    →  J PR[81] R[81]% CNT R[83] ...    │ │
│  │  FANUC_REMOTE_MOVEL   →  L PR[81] R[81]mm/s CNT R[83] ... │ │
│  │  FANUC_REMOTE_JOG     →  Continuous follower loop          │ │
│  │  SET_UTOOL_TP         →  UTOOL_NUM = R[84]                │ │
│  │  SET_UFRAME_TP        →  UFRAME_NUM = R[85]               │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↕                                   │
│                     Robot Motion Control                         │
└─────────────────────────────────────────────────────────────────┘
                              ↕
                    TCP/IP (Port 18735)
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                      External Client (Python)                    │
│                                                                   │
│  from fanucpy.robot import Robot                                 │
│                                                                   │
│  robot = Robot(host="192.168.1.100", port=18735)                │
│  robot.connect()                                                 │
│  robot.move("joint", vals=[0, -90, 0, 0, 0, 0])                │
│  pos = robot.get_curpos()                                        │
│  robot.jog_start("X", "+", speed=50)                            │
│  robot.disconnect()                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Organization

### KAREL Files (.kl)

These files contain the server logic written in FANUC's KAREL language:

| File | Lines | Purpose |
|------|-------|---------|
| `fanuc_remote_server.kl` | 146 | Main program, connection handling, main loop |
| `fanuc_remote_cmd.kl` | 1178 | Command parsing and execution handlers |
| `fanuc_remote_jog.kl` | 560 | Continuous jogging functionality |
| `fanuc_remote_comm.kl` | 73 | Socket communication utilities |
| `fanuc_remote_context.kl` | 41 | Kinematic context management |
| `fanuc_remote_utils.kl` | 15 | Utility functions |
| `fanuc_remote_logger.kl` | 84 | Logging and debugging |

### TP Files (.ls)

These files are Teach Pendant programs that execute robot motion:

| File | Lines | Purpose |
|------|-------|---------|
| `fanuc_remote.ls` | 26 | Entry point, runs FANUC_SVR and FANUC_LOG |
| `fanuc_remote_move.ls` | 27 | Joint motion: `J PR[81]...` |
| `fanuc_remote_movel.ls` | 27 | Linear motion: `L PR[81]...` |
| `FANUC_REMOTE_JOG.ls` | 32 | Continuous jog follower loop |
| `SET_UTOOL_TP.ls` | 26 | Set tool frame: `UTOOL_NUM=R[84]` |
| `SET_UFRAME_TP.ls` | 26 | Set user frame: `UFRAME_NUM=R[85]` |

---

## How Commands Flow Through the System

### Example: Joint Motion Command

```
Step 1: Client sends command
┌─────────────────────────────────────────────────────────┐
│ Python:                                                  │
│   robot.move("joint", vals=[0, -90, 0, 0, 0, 0])       │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ TCP/IP Socket:                                           │
│   "movej:0050:0100:050:0:6:+00000000.0000:              │
│    -00000090.0000:+00000000.0000:+00000000.0000:        │
│    +00000000.0000:+00000000.0000\n"                     │
└─────────────────────────────────────────────────────────┘
                        ↓
Step 2: Server receives and dispatches
┌─────────────────────────────────────────────────────────┐
│ FANUC_SVR main loop:                                     │
│   READ comm_file(cmd::0)  ← Non-blocking read          │
│   keep_conn = HANDLE_CMD(cmd, resp)                    │
└─────────────────────────────────────────────────────────┘
                        ↓
Step 3: Command identification
┌─────────────────────────────────────────────────────────┐
│ HANDLE_CMD:                                              │
│   IF SUB_STR(cmd, 1, 5) = 'movej' THEN                 │
│     resp = MOVEJ(cmd)                                   │
└─────────────────────────────────────────────────────────┘
                        ↓
Step 4: Command parsing
┌─────────────────────────────────────────────────────────┐
│ MOVEJ routine:                                           │
│   • Parse velocity (50) → R[81]                         │
│   • Parse acceleration (100) → R[82]                    │
│   • Parse CNT value (50) → R[83]                        │
│   • Parse joint values → joint_vals array               │
└─────────────────────────────────────────────────────────┘
                        ↓
Step 5: Validation
┌─────────────────────────────────────────────────────────┐
│ MOVEJ routine:                                           │
│   • Convert to JOINTPOS: CNV_REL_JPOS(...)             │
│   • Forward kinematics: JOINT2POS(...)                  │
│   • Check reachability                                   │
│   • If error: RETURN('1:position-is-not-reachable')    │
└─────────────────────────────────────────────────────────┘
                        ↓
Step 6: Position storage
┌─────────────────────────────────────────────────────────┐
│ MOVEJ routine:                                           │
│   SET_JPOS_REG(81, jpos, status)                       │
│   PR[81] now contains target position                   │
└─────────────────────────────────────────────────────────┘
                        ↓
Step 7: TP program execution
┌─────────────────────────────────────────────────────────┐
│ MOVEJ routine:                                           │
│   CALL_PROGLIN('FANUC_REMOTE_MOVE', 1, prog_index, ...) │
│                                                          │
│ FANUC_REMOTE_MOVE.ls executes:                          │
│   J PR[81] R[81]% CNT R[83] ACC R[82]                  │
│   (Robot physically moves to position)                   │
└─────────────────────────────────────────────────────────┘
                        ↓
Step 8: Response sent
┌─────────────────────────────────────────────────────────┐
│ MOVEJ routine:                                           │
│   RETURN('0:success')                                   │
│                                                          │
│ FANUC_SVR main loop:                                     │
│   WRITE comm_file(resp)                                 │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ TCP/IP Socket:                                           │
│   "0:success\n"                                         │
└─────────────────────────────────────────────────────────┘
                        ↓
Step 9: Client receives response
┌─────────────────────────────────────────────────────────┐
│ Python:                                                  │
│   Motion complete, continue execution                    │
└─────────────────────────────────────────────────────────┘
```

---

## How Jogging Works

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Condition Handler (Timer)                │
│                                                          │
│  Every 30ms (jog_interval):                             │
│    cont_timer >= jog_interval → jog_tick_due = TRUE    │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│             FANUC_SVR Main Loop Checks                   │
│                                                          │
│  IF jog_tick_due AND (NOT jog_in_progr) THEN           │
│    jog_in_progr = TRUE                                  │
│    JOG_TICK                                             │
│    jog_in_progr = FALSE                                 │
│    jog_tick_due = FALSE                                 │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│                    JOG_TICK Routine                      │
│                                                          │
│  1. Apply kinematic context (APL_KIN_CTX)               │
│  2. Calculate delta for each active axis:               │
│     IF jog_active[1] THEN  ← X axis                    │
│       delta.x = ±jog_step_lin * (jog_speed/100)        │
│  3. Transform delta based on coordinate system:         │
│     • WORLD: Direct addition                            │
│     • USER:  Transform via user frame                   │
│     • TOOL:  Transform via tool frame                   │
│  4. Update working position: jog_pr += delta            │
│  5. Write to position register (double buffering):      │
│     SET_POS_REG(pr_num, jog_pr, status)                │
│     Toggle pr_num between 81 and 82                     │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│           FANUC_REMOTE_JOG.ls (Running in TP)           │
│                                                          │
│  LBL[1]:                                                │
│    L PR[81] R[81]mm/sec CNT R[83] ACC R[82]            │
│    L PR[82] R[81]mm/sec CNT R[83] ACC R[82]            │
│    IF (R[89]=1) JMP LBL[1]                             │
│  END                                                     │
│                                                          │
│  Robot continuously follows updated positions            │
└─────────────────────────────────────────────────────────┘
```

### Double Buffering Mechanism

```
Time    KAREL writes to:    TP reads from:    Result
─────   ──────────────────  ─────────────────  ──────────────────
t=0     PR[81] (pos A)      -                  Initialize
t=30    PR[82] (pos B)      PR[81] (pos A)     Robot moves to A
t=60    PR[81] (pos C)      PR[82] (pos B)     Robot moves to B
t=90    PR[82] (pos D)      PR[81] (pos C)     Robot moves to C
t=120   PR[81] (pos E)      PR[82] (pos D)     Robot moves to D
...     ...                 ...                ...
```

**Why double buffering?**
- Prevents race conditions (TP reading while KAREL writing)
- Ensures smooth continuous motion
- No partial/corrupted position data

---

## Key Design Decisions

### 1. Non-Blocking Socket Reads

```karel
READ comm_file(cmd::0)  -- ::0 makes it non-blocking
```

**Why?**
- Allows server to process jog ticks while waiting for commands
- Server remains responsive
- No blocking on slow clients

### 2. Separation of KAREL and TP Programs

**KAREL:**
- Command processing
- State management
- Position calculations
- Validation

**TP:**
- Actual motion execution
- Native motion instructions
- Hardware acceleration

**Why separate?**
- KAREL cannot directly execute motion
- TP has optimized motion control
- Clean separation of concerns

### 3. Position Register Strategy

**Motion commands:** Use PR[81] only
**Jogging:** Alternate between PR[81] and PR[82]

**Why different strategies?**
- Motion commands are synchronous (one at a time)
- Jogging is continuous (needs double buffering)

### 4. Global State Variables

```karel
g_tool_num, g_uframe_num, g_coord_type
```

**Why global?**
- Persistent across commands
- Applied via APL_KIN_CTX before every motion
- Consistent behavior

---

## Command Response Format

All commands follow the same response pattern:

```
Success: "0:<message or data>"
Error:   "1:<error description>"
```

**Examples:**

| Command | Response |
|---------|----------|
| `curpos` | `0:x=500.123,y=200.456,z=300.789,...` |
| `movej:...` | `0:success` |
| `get_tool` | `0:5` |
| `jog_start:X:+:50` | `0:OK` |
| `invalid_cmd` | `1:wrong-command` |
| `movej:...` (unreachable) | `1:position-is-not-reachable` |

**Parsing in Python:**

```python
response = socket.recv(1024).decode().strip()
code, message = response.split(':', 1)

if code == '0':
    # Success
    process_success(message)
else:
    # Error
    raise RobotError(message)
```

---

## Performance Characteristics

### Command Latency

| Command Type | Typical Latency | Notes |
|--------------|----------------|-------|
| Position query | 5-10 ms | Fast, no motion |
| I/O commands | 10-20 ms | Direct register access |
| Motion commands | 50-200 ms | Depends on distance/speed |
| Jog start/stop | 10-30 ms | State change only |

### Jog Performance

- **Tick interval:** 30 ms (configurable via `jog_interval`)
- **Default step size:** 2.0 mm (linear), 1.0° (rotational)
- **Update rate:** ~33 Hz
- **Smoothness:** High (double buffering + CNT blending)

### Network Requirements

- **Bandwidth:** Very low (<1 KB/s typical)
- **Latency sensitivity:** Moderate (50-100ms acceptable)
- **Connection type:** TCP (reliable, ordered)

---

## Error Handling Strategy

### Validation Layers

```
Layer 1: Command syntax
  ↓ Invalid command → "1:wrong-command"
  
Layer 2: Parameter parsing
  ↓ Parse error → "1:error-in-joint-values"
  
Layer 3: Value validation
  ↓ Out of range → "1:ERR OUT_OF_RANGE"
  
Layer 4: Kinematic validation
  ↓ Unreachable → "1:position-is-not-reachable"
  
Layer 5: Register access
  ↓ Register error → "1:R[nn]-was-not-set"
  
Layer 6: Motion execution
  ↓ Motion error → (handled by TP program)
```

### Recovery

- **Syntax errors:** Client should retry with corrected command
- **Unreachable positions:** Client should adjust target
- **Register errors:** May indicate robot mode issue (check AUTO mode)
- **Connection errors:** Server closes connection, client should reconnect

---

## Security Considerations

### Current Implementation

- **No authentication:** Anyone with network access can connect
- **No encryption:** Commands sent in plain text
- **Single client:** Only one client can connect at a time
- **No command validation beyond syntax:** Trust client to send safe commands

### Recommendations for Production

1. **Network isolation:** Robot network should be separate from general network
2. **Firewall rules:** Restrict access to port 18735
3. **Position limits:** Enforce software limits in KAREL
4. **Emergency stop:** Always have physical E-stop accessible
5. **Monitoring:** Log all commands for audit trail

---

## Extending the Driver

### Adding New Commands

1. **Create handler routine** in `fanuc_remote_cmd.kl`:

```karel
ROUTINE MY_NEW_CMD(cmd: STRING): STRING
VAR
    resp: STRING[254]
BEGIN
    -- Parse arguments
    -- Validate inputs
    -- Execute operation
    resp = '0:success'
    RETURN(resp)
END MY_NEW_CMD
```

2. **Register in HANDLE_CMD**:

```karel
IF SUB_STR(cmd, 1, 10) = 'mynewcmd' THEN
    resp = MY_NEW_CMD(cmd)
    RETURN(TRUE)
ENDIF
```

3. **Update Python client** (optional):

```python
def my_new_operation(self, param):
    cmd = f"mynewcmd:{param}"
    response = self.send_cmd(cmd)
    return response
```

### Adding New TP Programs

1. Create TP program on controller
2. Call from KAREL using `CALL_PROG` or `CALL_PROGLIN`
3. Use registers to pass parameters

---

## Troubleshooting Guide

### Connection Issues

**Problem:** Cannot connect to robot

**Checks:**
1. Verify robot is on correct network
2. Ping robot IP address
3. Check firewall settings
4. Verify FANUC_SVR is running on controller
5. Check port 18735 is not blocked

### Motion Issues

**Problem:** `1:position-is-not-reachable`

**Solutions:**
1. Check target position is within workspace
2. Verify tool and user frames are correct
3. Check for singularities
4. Ensure robot is in proper configuration

**Problem:** Motion is jerky

**Solutions:**
1. Increase CNT value (50-100)
2. Reduce velocity
3. Use linear motion instead of joint motion

### Jogging Issues

**Problem:** Jogging doesn't respond

**Checks:**
1. Verify jog_start returned `0:OK`
2. Check R[89] is set to 1
3. Ensure FANUC_REMOTE_JOG.ls is running
4. Verify coordinate system is set correctly

**Problem:** Jogging is too fast/slow

**Solution:**
- Adjust speed parameter: `jog_start:X:+:25`
- Adjust step size: `jog_start:X:+:75:0.5`

---

## Further Reading

- [**Driver Architecture**](driver_architecture.md) - Detailed technical documentation
- [**Command Reference**](command_reference.md) - Complete command list with examples
- [**System Architecture**](architecture.md) - High-level system overview
- [**Jogging Guide**](jogging.md) - Jogging functionality details
- [**Frames and Coordinates**](frames_and_coords.md) - Frame management guide

---

## Summary

The FANUC driver is a well-architected TCP/IP server that:

✅ Uses simple text-based protocol for easy integration  
✅ Implements non-blocking I/O for responsiveness  
✅ Separates command logic (KAREL) from motion execution (TP)  
✅ Maintains global state for consistent behavior  
✅ Provides smooth jogging through double buffering  
✅ Includes comprehensive error handling and validation  
✅ Supports flexible coordinate systems (WORLD/USER/TOOL)  
✅ Enables sophisticated external applications  

The modular design makes it easy to extend with new commands while maintaining robustness and safety.

