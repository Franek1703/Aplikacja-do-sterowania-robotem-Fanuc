"""
Status publisher.

Periodically publishes robot and device status to Firebase RTDB.
See firebase_protocol.md section 3 for data structure.
"""

import logging
import time
import threading
from typing import Optional

from firebase_admin import db

try:
    from .robot_adapter import RobotInterface
    from .models import RobotPose, RobotJoints, RobotConfig, RobotStatus, DeviceStatus
except ImportError:
    from robot_adapter import RobotInterface
    from models import RobotPose, RobotJoints, RobotConfig, RobotStatus, DeviceStatus

logger = logging.getLogger(__name__)


class StatusPublisher:
    """Publishes robot and device status to Firebase RTDB.
    
    Runs in a separate thread and updates status at regular intervals.
    """
    
    def __init__(
        self,
        device_id: str,
        robot_id: str,
        robot: RobotInterface,
        rtdb_root: db.Reference,
        interval: float = 0.2,
    ):
        """Initialize status publisher.
        
        Args:
            device_id: Device (Raspberry Pi) identifier
            robot_id: Robot identifier
            robot: Robot interface
            rtdb_root: Firebase RTDB root reference
            interval: Update interval in seconds (default: 0.2s = 200ms)
        """
        self.device_id = device_id
        self.robot_id = robot_id
        self.robot = robot
        self.rtdb_root = rtdb_root
        self.interval = interval
        
        self._running = False
        self._thread: Optional[threading.Thread] = None
        
        # RTDB references
        self.device_ref = rtdb_root.child(f"devices/{device_id}")
        self.robot_ref = self.device_ref.child(f"robots/{robot_id}")
        
        logger.info(f"Initialized StatusPublisher for device={device_id}, robot={robot_id}")
    
    def start(self) -> None:
        """Start the status publisher thread."""
        if self._running:
            logger.warning("StatusPublisher already running")
            return
        
        self._running = True
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()
        
        logger.info("StatusPublisher started")
    
    def stop(self) -> None:
        """Stop the status publisher thread."""
        if not self._running:
            return
        
        self._running = False
        
        if self._thread:
            self._thread.join(timeout=5.0)
        
        logger.info("StatusPublisher stopped")
    
    def _run_loop(self) -> None:
        """Main loop for status publishing."""
        logger.info("StatusPublisher loop started")
        
        while self._running:
            try:
                self._publish_status()
            except Exception as e:
                logger.error(f"Error publishing status: {e}", exc_info=True)
            
            # Sleep for the configured interval
            time.sleep(self.interval)
        
        logger.info("StatusPublisher loop ended")
    
    def _publish_status(self) -> None:
        """Publish current status to Firebase.
        
        Updates:
        - Device status (online, lastSeen)
        - Robot status (online, mode, eStop, alarmCount)
        - Current pose
        - Current joints
        - Robot configuration
        """
        current_time = int(time.time())
        
        try:
            # Publish device status
            device_status = DeviceStatus(online=True, lastSeen=current_time)
            self.device_ref.child("status").set(device_status.to_dict())
            
            # Get robot data
            try:
                pose_vals = self.robot.get_curpos()
                pose = RobotPose(
                    x=pose_vals[0],
                    y=pose_vals[1],
                    z=pose_vals[2],
                    w=pose_vals[3],
                    p=pose_vals[4],
                    r=pose_vals[5],
                    updatedAt=current_time
                )
            except Exception as e:
                logger.warning(f"Failed to get current pose: {e}")
                pose = None
            
            try:
                joint_vals = self.robot.get_curjpos()
                joints = RobotJoints(
                    j1=joint_vals[0],
                    j2=joint_vals[1],
                    j3=joint_vals[2],
                    j4=joint_vals[3],
                    j5=joint_vals[4],
                    j6=joint_vals[5],
                    updatedAt=current_time
                )
            except Exception as e:
                logger.warning(f"Failed to get current joints: {e}")
                joints = None
            
            # Get configuration
            try:
                _, tool_str = self.robot.get_tool()
                tool_num = int(tool_str)
            except Exception as e:
                logger.debug(f"Failed to get tool number: {e}")
                tool_num = 1
            
            try:
                _, user_str = self.robot.get_user()
                user_frame = int(user_str)
            except Exception as e:
                logger.debug(f"Failed to get user frame: {e}")
                user_frame = 0
            
            try:
                _, coord_str = self.robot.get_coord()
                coord_system = coord_str
            except Exception as e:
                logger.debug(f"Failed to get coord system: {e}")
                coord_system = "WORLD"
            
            config = RobotConfig(
                userFrame=user_frame,
                toolNumber=tool_num,
                coordSystem=coord_system,
                activeProgram=None  # Would need to track this
            )
            
            # Robot status (simplified - would need real mode/estop detection)
            status = RobotStatus(
                online=True,
                mode="MANUAL",  # Would need to query actual mode
                eStop=False,    # Would need to query actual e-stop state
                alarmCount=0    # Would need to query actual alarms
            )
            
            # Publish robot data
            self.robot_ref.child("status").set(status.to_dict())
            
            if pose:
                self.robot_ref.child("currentPose").set(pose.to_dict())
            
            if joints:
                self.robot_ref.child("currentJoints").set(joints.to_dict())
            
            self.robot_ref.child("config").set(config.to_dict())
            
            logger.debug(f"Published status for robot {self.robot_id}")
            
        except Exception as e:
            logger.error(f"Error in _publish_status: {e}", exc_info=True)
    
    def publish_once(self) -> None:
        """Publish status once (useful for testing)."""
        self._publish_status()

