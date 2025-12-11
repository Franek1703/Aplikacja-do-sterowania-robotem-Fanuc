"""
Data models for Firebase Gateway.

All models follow the structure defined in firebase_protocol.md.
"""

from dataclasses import dataclass, field, asdict
from typing import Literal, Optional, Dict, Any, List, Union
from datetime import datetime
import time

# Command types as defined in firebase_protocol.md
CommandType = Literal[
    # Motion commands
    "move", "jogStart", "jogStop", "jogStopAll",
    # Program execution
    "runProgram", "abortProgram", "selectProgram",
    # Gripper control
    "setGripper",
    # Robot I/O
    "setRDO", "getRDO", "setDOUT", "getDOUT",
    # System variables
    "getSystemVar", "setSystemVar",
    # Robot configuration
    "setTool", "setUserFrame", "setCoord",
    # Diagnostics
    "getPowerConsumption", "getRobotInfo"
]

# FTP command types as defined in firebase_protocol.md
FTPCommandType = Literal[
    "listFiles", "readFile", "writeFile", "deleteFile",
    "renameFile", "createDirectory", "removeDirectory"
]

# Command status
CommandStatus = Literal["pending", "running", "success", "error"]

# Robot mode
RobotMode = Literal["T1", "T2", "MANUAL", "AUTO"]

# Coordinate system
CoordSystem = Literal["WORLD", "USER", "TOOL"]


@dataclass
class CommandResult:
    """Result of a command execution.
    
    As defined in firebase_protocol.md section 4.
    """
    code: Optional[int] = None
    message: Optional[str] = None
    completedAt: Optional[int] = None
    data: Optional[Dict[str, Any]] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return {k: v for k, v in asdict(self).items() if v is not None}


@dataclass
class Command:
    """Robot command structure.
    
    As defined in firebase_protocol.md section 4.
    """
    type: CommandType
    status: CommandStatus
    createdAt: int
    createdBy: str
    payload: Dict[str, Any] = field(default_factory=dict)
    result: CommandResult = field(default_factory=CommandResult)
    commandId: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        data = asdict(self)
        data['result'] = self.result.to_dict()
        if self.commandId is not None:
            data['commandId'] = self.commandId
        return data
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any], command_id: Optional[str] = None) -> "Command":
        """Create Command from Firebase dictionary."""
        result_data = data.get('result', {})
        result = CommandResult(
            code=result_data.get('code'),
            message=result_data.get('message'),
            completedAt=result_data.get('completedAt'),
            data=result_data.get('data')
        )
        
        return cls(
            type=data['type'],
            status=data['status'],
            createdAt=data['createdAt'],
            createdBy=data['createdBy'],
            payload=data.get('payload', {}),
            result=result,
            commandId=command_id
        )


@dataclass
class FTPCommand:
    """FTP command structure.
    
    As defined in firebase_protocol.md section 6.
    """
    type: FTPCommandType
    status: CommandStatus
    createdAt: int
    createdBy: str
    payload: Dict[str, Any] = field(default_factory=dict)
    result: CommandResult = field(default_factory=CommandResult)
    requestId: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        data = asdict(self)
        data['result'] = self.result.to_dict()
        if self.requestId is not None:
            data['requestId'] = self.requestId
        return data
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any], request_id: Optional[str] = None) -> "FTPCommand":
        """Create FTPCommand from Firebase dictionary."""
        result_data = data.get('result', {})
        result = CommandResult(
            code=result_data.get('code'),
            message=result_data.get('message'),
            completedAt=result_data.get('completedAt'),
            data=result_data.get('data')
        )
        
        return cls(
            type=data['type'],
            status=data['status'],
            createdAt=data['createdAt'],
            createdBy=data['createdBy'],
            payload=data.get('payload', {}),
            result=result,
            requestId=request_id
        )


@dataclass
class RobotPose:
    """Cartesian pose (XYZWPR).
    
    As defined in firebase_protocol.md section 3.1.
    """
    x: float
    y: float
    z: float
    w: float
    p: float
    r: float
    updatedAt: int = field(default_factory=lambda: int(time.time()))
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return asdict(self)


@dataclass
class RobotJoints:
    """Joint positions.
    
    As defined in firebase_protocol.md section 3.1.
    """
    j1: float
    j2: float
    j3: float
    j4: float
    j5: float
    j6: float
    updatedAt: int = field(default_factory=lambda: int(time.time()))
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return asdict(self)


@dataclass
class RobotConfig:
    """Robot configuration.
    
    As defined in firebase_protocol.md section 3.1.
    """
    userFrame: int = 0
    toolNumber: int = 1
    coordSystem: CoordSystem = "WORLD"
    activeProgram: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return {k: v for k, v in asdict(self).items() if v is not None}


@dataclass
class RobotStatus:
    """Robot status information.
    
    As defined in firebase_protocol.md section 3.1.
    """
    online: bool
    mode: RobotMode = "MANUAL"
    eStop: bool = False
    alarmCount: int = 0
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return asdict(self)


@dataclass
class DeviceStatus:
    """Device (Raspberry Pi) status.
    
    As defined in firebase_protocol.md section 3.1.
    """
    online: bool
    lastSeen: int = field(default_factory=lambda: int(time.time()))
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return asdict(self)


@dataclass
class PowerConsumption:
    """Power consumption data.
    
    As defined in firebase_protocol.md section 5.7.
    """
    voltage: float
    current: float
    power: float
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return asdict(self)


@dataclass
class FileInfo:
    """File information from FTP listing."""
    name: str
    size: int
    modify_time: str
    is_dir: bool
    permissions: str
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return asdict(self)


@dataclass
class ParameterDefinition:
    """Parameter definition from Firestore."""
    id: str
    name: str
    defaultValue: Any
    type: Literal["string", "number", "boolean"]
    category: Literal["Network", "Motion", "System"]
    isLocked: bool
    description: str
    unit: Optional[str] = None
    minValue: Optional[float] = None
    maxValue: Optional[float] = None


@dataclass
class ParameterValue:
    """Parameter value in RTDB."""
    value: Any
    updatedAt: int
    updatedBy: str
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Firebase."""
        return asdict(self)


@dataclass
class ParameterUpdate:
    """Parameter update command payload."""
    parameterId: str
    value: Any

