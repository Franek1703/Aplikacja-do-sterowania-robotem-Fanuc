"""
Robot adapter layer.

Provides a common interface for both real and simulated robots.
See firebase_protocol.md for command specifications.
"""

import logging
import time
from typing import Protocol, List, Tuple, Literal, Optional, Dict, Any
from dataclasses import dataclass

try:
    from .models import RobotPose, RobotJoints, RobotConfig, RobotStatus, PowerConsumption
except ImportError:
    from models import RobotPose, RobotJoints, RobotConfig, RobotStatus, PowerConsumption

logger = logging.getLogger(__name__)


class RobotInterface(Protocol):
    """Protocol defining the robot interface.
    
    All methods correspond to commands defined in firebase_protocol.md.
    """
    
    # Connection management
    def connect(self) -> Tuple[int, str]:
        """Connect to the robot."""
        ...
    
    def disconnect(self) -> None:
        """Disconnect from the robot."""
        ...
    
    # Status queries
    def get_curpos(self) -> List[float]:
        """Get current cartesian position [x, y, z, w, p, r]."""
        ...
    
    def get_curjpos(self) -> List[float]:
        """Get current joint positions [j1, j2, j3, j4, j5, j6]."""
        ...
    
    def get_power_consumption(self) -> float:
        """Get instantaneous power consumption in watts."""
        ...
    
    # Motion commands
    def move(
        self,
        move_type: Literal["joint", "pose"],
        vals: List[float],
        velocity: int,
        acceleration: int,
        cnt_val: int,
        linear: bool,
    ) -> Tuple[int, str]:
        """Execute a move command."""
        ...
    
    def jog_start(
        self,
        axis: Literal["X", "Y", "Z", "W", "P", "R"],
        direction: Literal["+", "-"],
        speed: Optional[int] = None,
        step: Optional[float] = None,
    ) -> Tuple[int, str]:
        """Start jogging an axis."""
        ...
    
    def jog_stop(self, axis: Literal["X", "Y", "Z", "W", "P", "R"]) -> Tuple[int, str]:
        """Stop jogging an axis."""
        ...
    
    def jog_stop_all(self) -> Tuple[int, str]:
        """Stop all jogging operations."""
        ...
    
    # Program execution
    def call_prog(self, prog_name: str) -> Tuple[int, str]:
        """Call/run a program."""
        ...
    
    # Gripper control
    def gripper(self, value: bool) -> Tuple[int, str]:
        """Control gripper (open/close)."""
        ...
    
    # I/O operations
    def set_rdo(self, rdo_num: int, val: bool) -> Tuple[int, str]:
        """Set Robot Digital Output."""
        ...
    
    def get_rdo(self, rdo_num: int) -> int:
        """Get Robot Digital Output value."""
        ...
    
    def set_dout(self, dout_num: int, val: bool) -> Tuple[int, str]:
        """Set Digital Output."""
        ...
    
    def get_dout(self, dout_num: int) -> int:
        """Get Digital Output value."""
        ...
    
    # System variables
    def set_sys_var(self, sys_var: str, val: bool) -> Tuple[int, str]:
        """Set system variable."""
        ...
    
    # Configuration
    def set_tool(self, tool_num: int) -> Tuple[int, str]:
        """Set tool number."""
        ...
    
    def set_user(self, user_num: int) -> Tuple[int, str]:
        """Set user frame number."""
        ...
    
    def set_coord(self, coord_type: Literal["WORLD", "USER", "TOOL"]) -> Tuple[int, str]:
        """Set coordinate system."""
        ...
    
    def get_tool(self) -> Tuple[int, str]:
        """Get current tool number."""
        ...
    
    def get_user(self) -> Tuple[int, str]:
        """Get current user frame number."""
        ...
    
    def get_coord(self) -> Tuple[int, str]:
        """Get current coordinate system."""
        ...


class RealRobotAdapter:
    """Adapter for real FANUC robot hardware.
    
    Wraps the existing Robot class from fanuc_package.
    """
    
    def __init__(
        self,
        host: str,
        port: int = 18735,
        ftp_user: str = "anonymous",
        ftp_password: str = "",
        ee_do_type: Optional[str] = None,
        ee_do_num: Optional[int] = None,
    ):
        """Initialize real robot adapter.
        
        Args:
            host: Robot IP address
            port: Robot socket port
            ftp_user: FTP username
            ftp_password: FTP password
            ee_do_type: End effector digital output type (e.g., "RDO")
            ee_do_num: End effector digital output number
        """
        # Import here to avoid dependency in simulation mode
        import sys
        from pathlib import Path
        
        # Add fanuc_package to path if needed
        fanuc_package_path = Path(__file__).parent.parent / "fanuc_package" / "src"
        if str(fanuc_package_path) not in sys.path:
            sys.path.insert(0, str(fanuc_package_path))
        
        from robot.robot import Robot
        
        self.robot = Robot(
            robot_model="Fanuc",
            host=host,
            port=port,
            ee_DO_type=ee_do_type,
            ee_DO_num=ee_do_num,
            ftp_user=ftp_user,
            ftp_password=ftp_password,
        )
        
        logger.info(f"Initialized RealRobotAdapter for {host}:{port}")
    
    def connect(self) -> Tuple[int, str]:
        """Connect to the robot."""
        return self.robot.connect()
    
    def disconnect(self) -> None:
        """Disconnect from the robot."""
        self.robot.disconnect()
    
    def get_curpos(self) -> List[float]:
        """Get current cartesian position."""
        return self.robot.get_curpos()
    
    def get_curjpos(self) -> List[float]:
        """Get current joint positions."""
        return self.robot.get_curjpos()
    
    def get_power_consumption(self) -> float:
        """Get instantaneous power consumption."""
        return self.robot.get_ins_power()
    
    def move(
        self,
        move_type: Literal["joint", "pose"],
        vals: List[float],
        velocity: int,
        acceleration: int,
        cnt_val: int,
        linear: bool,
    ) -> Tuple[int, str]:
        """Execute a move command."""
        return self.robot.move(
            move_type=move_type,
            vals=vals,
            velocity=velocity,
            acceleration=acceleration,
            cnt_val=cnt_val,
            linear=linear,
        )
    
    def jog_start(
        self,
        axis: Literal["X", "Y", "Z", "W", "P", "R"],
        direction: Literal["+", "-"],
        speed: Optional[int] = None,
        step: Optional[float] = None,
    ) -> Tuple[int, str]:
        """Start jogging an axis."""
        return self.robot.jog_start(axis=axis, direction=direction, speed=speed, step=step)
    
    def jog_stop(self, axis: Literal["X", "Y", "Z", "W", "P", "R"]) -> Tuple[int, str]:
        """Stop jogging an axis."""
        return self.robot.jog_stop(axis=axis)
    
    def jog_stop_all(self) -> Tuple[int, str]:
        """Stop all jogging operations."""
        return self.robot.jog_stop_all()
    
    def call_prog(self, prog_name: str) -> Tuple[int, str]:
        """Call/run a program."""
        return self.robot.call_prog(prog_name)
    
    def gripper(self, value: bool) -> Tuple[int, str]:
        """Control gripper."""
        return self.robot.gripper(value)
    
    def set_rdo(self, rdo_num: int, val: bool) -> Tuple[int, str]:
        """Set Robot Digital Output."""
        return self.robot.set_rdo(rdo_num, val)
    
    def get_rdo(self, rdo_num: int) -> int:
        """Get Robot Digital Output value."""
        return self.robot.get_rdo(rdo_num)
    
    def set_dout(self, dout_num: int, val: bool) -> Tuple[int, str]:
        """Set Digital Output."""
        return self.robot.set_dout(dout_num, val)
    
    def get_dout(self, dout_num: int) -> int:
        """Get Digital Output value."""
        return self.robot.get_dout(dout_num)
    
    def set_sys_var(self, sys_var: str, val: bool) -> Tuple[int, str]:
        """Set system variable."""
        return self.robot.set_sys_var(sys_var, val)
    
    def set_tool(self, tool_num: int) -> Tuple[int, str]:
        """Set tool number."""
        return self.robot.set_tool(tool_num)
    
    def set_user(self, user_num: int) -> Tuple[int, str]:
        """Set user frame number."""
        return self.robot.set_user(user_num)
    
    def set_coord(self, coord_type: Literal["WORLD", "USER", "TOOL"]) -> Tuple[int, str]:
        """Set coordinate system."""
        return self.robot.set_coord(coord_type)
    
    def get_tool(self) -> Tuple[int, str]:
        """Get current tool number."""
        return self.robot.get_tool()
    
    def get_user(self) -> Tuple[int, str]:
        """Get current user frame number."""
        return self.robot.get_user()
    
    def get_coord(self) -> Tuple[int, str]:
        """Get current coordinate system."""
        return self.robot.get_coord()


class SimulatedRobotAdapter:
    """Simulated robot for testing without hardware.
    
    Maintains internal state and logs all operations.
    """
    
    def __init__(self):
        """Initialize simulated robot with default state."""
        self.connected = False
        self.position = [450.0, 0.0, 300.0, 180.0, 0.0, 90.0]  # x, y, z, w, p, r
        self.joints = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # j1-j6
        self.tool_num = 1
        self.user_frame = 0
        self.coord_system = "WORLD"
        self.rdo_states: Dict[int, bool] = {}
        self.dout_states: Dict[int, bool] = {}
        self.gripper_open = False
        self.active_program: Optional[str] = None
        self.power_consumption = 450.0  # watts
        
        logger.info("Initialized SimulatedRobotAdapter")
    
    def connect(self) -> Tuple[int, str]:
        """Simulate connection."""
        logger.info("SimulatedRobot: Connecting...")
        self.connected = True
        return (0, "Connected to simulated robot")
    
    def disconnect(self) -> None:
        """Simulate disconnection."""
        logger.info("SimulatedRobot: Disconnecting...")
        self.connected = False
    
    def get_curpos(self) -> List[float]:
        """Get simulated cartesian position."""
        logger.debug(f"SimulatedRobot: get_curpos() -> {self.position}")
        return self.position.copy()
    
    def get_curjpos(self) -> List[float]:
        """Get simulated joint positions."""
        logger.debug(f"SimulatedRobot: get_curjpos() -> {self.joints}")
        return self.joints.copy()
    
    def get_power_consumption(self) -> float:
        """Get simulated power consumption."""
        # Add some variation
        import random
        power = self.power_consumption + random.uniform(-50, 50)
        logger.debug(f"SimulatedRobot: get_power_consumption() -> {power}W")
        return power
    
    def move(
        self,
        move_type: Literal["joint", "pose"],
        vals: List[float],
        velocity: int,
        acceleration: int,
        cnt_val: int,
        linear: bool,
    ) -> Tuple[int, str]:
        """Simulate move command."""
        logger.info(f"SimulatedRobot: move({move_type}, vals={vals}, vel={velocity}, "
                   f"acc={acceleration}, cnt={cnt_val}, linear={linear})")
        
        if move_type == "pose":
            self.position = vals.copy()
        elif move_type == "joint":
            self.joints = vals.copy()
        
        # Simulate some delay
        time.sleep(0.1)
        
        return (0, f"Moved to {move_type} position")
    
    def jog_start(
        self,
        axis: Literal["X", "Y", "Z", "W", "P", "R"],
        direction: Literal["+", "-"],
        speed: Optional[int] = None,
        step: Optional[float] = None,
    ) -> Tuple[int, str]:
        """Simulate jog start."""
        logger.info(f"SimulatedRobot: jog_start(axis={axis}, direction={direction}, "
                   f"speed={speed}, step={step})")
        
        # Update position slightly
        axis_map = {"X": 0, "Y": 1, "Z": 2, "W": 3, "P": 4, "R": 5}
        idx = axis_map[axis]
        delta = (step or 0.25) if direction == "+" else -(step or 0.25)
        self.position[idx] += delta
        
        return (0, f"Started jogging {axis}{direction}")
    
    def jog_stop(self, axis: Literal["X", "Y", "Z", "W", "P", "R"]) -> Tuple[int, str]:
        """Simulate jog stop."""
        logger.info(f"SimulatedRobot: jog_stop(axis={axis})")
        return (0, f"Stopped jogging {axis}")
    
    def jog_stop_all(self) -> Tuple[int, str]:
        """Simulate stop all jogging."""
        logger.info("SimulatedRobot: jog_stop_all()")
        return (0, "Stopped all jogging")
    
    def call_prog(self, prog_name: str) -> Tuple[int, str]:
        """Simulate program call."""
        logger.info(f"SimulatedRobot: call_prog(prog_name={prog_name})")
        self.active_program = prog_name
        time.sleep(0.5)  # Simulate program execution
        return (0, f"Executed program {prog_name}")
    
    def gripper(self, value: bool) -> Tuple[int, str]:
        """Simulate gripper control."""
        logger.info(f"SimulatedRobot: gripper(value={value})")
        self.gripper_open = value
        return (0, f"Gripper {'opened' if value else 'closed'}")
    
    def set_rdo(self, rdo_num: int, val: bool) -> Tuple[int, str]:
        """Simulate set RDO."""
        logger.info(f"SimulatedRobot: set_rdo(rdo_num={rdo_num}, val={val})")
        self.rdo_states[rdo_num] = val
        return (0, f"RDO[{rdo_num}] set to {val}")
    
    def get_rdo(self, rdo_num: int) -> int:
        """Simulate get RDO."""
        val = self.rdo_states.get(rdo_num, False)
        logger.debug(f"SimulatedRobot: get_rdo(rdo_num={rdo_num}) -> {val}")
        return int(val)
    
    def set_dout(self, dout_num: int, val: bool) -> Tuple[int, str]:
        """Simulate set DOUT."""
        logger.info(f"SimulatedRobot: set_dout(dout_num={dout_num}, val={val})")
        self.dout_states[dout_num] = val
        return (0, f"DOUT[{dout_num}] set to {val}")
    
    def get_dout(self, dout_num: int) -> int:
        """Simulate get DOUT."""
        val = self.dout_states.get(dout_num, False)
        logger.debug(f"SimulatedRobot: get_dout(dout_num={dout_num}) -> {val}")
        return int(val)
    
    def set_sys_var(self, sys_var: str, val: bool) -> Tuple[int, str]:
        """Simulate set system variable."""
        logger.info(f"SimulatedRobot: set_sys_var(sys_var={sys_var}, val={val})")
        return (0, f"System variable {sys_var} set to {val}")
    
    def set_tool(self, tool_num: int) -> Tuple[int, str]:
        """Simulate set tool."""
        logger.info(f"SimulatedRobot: set_tool(tool_num={tool_num})")
        self.tool_num = tool_num
        return (0, f"Tool set to {tool_num}")
    
    def set_user(self, user_num: int) -> Tuple[int, str]:
        """Simulate set user frame."""
        logger.info(f"SimulatedRobot: set_user(user_num={user_num})")
        self.user_frame = user_num
        return (0, f"User frame set to {user_num}")
    
    def set_coord(self, coord_type: Literal["WORLD", "USER", "TOOL"]) -> Tuple[int, str]:
        """Simulate set coordinate system."""
        logger.info(f"SimulatedRobot: set_coord(coord_type={coord_type})")
        self.coord_system = coord_type
        return (0, f"Coordinate system set to {coord_type}")
    
    def get_tool(self) -> Tuple[int, str]:
        """Simulate get tool."""
        logger.debug(f"SimulatedRobot: get_tool() -> {self.tool_num}")
        return (0, str(self.tool_num))
    
    def get_user(self) -> Tuple[int, str]:
        """Simulate get user frame."""
        logger.debug(f"SimulatedRobot: get_user() -> {self.user_frame}")
        return (0, str(self.user_frame))
    
    def get_coord(self) -> Tuple[int, str]:
        """Simulate get coordinate system."""
        logger.debug(f"SimulatedRobot: get_coord() -> {self.coord_system}")
        return (0, self.coord_system)

