"""
Robot Session Manager for dynamic robot switching.

Watches for selectedRobotId changes in RTDB and manages robot sessions accordingly.
"""

import logging
import time
import threading
from typing import Optional, Dict, Any
from dataclasses import dataclass
from datetime import datetime

try:
    from .firebase_client import get_firestore_client, get_rtdb_root
    from .robot_adapter import RealRobotAdapter, SimulatedRobotAdapter, RobotInterface
    from .ftp_bridge import FTPBridge
    from .dispatcher import CommandDispatcher
    from .status_publisher import StatusPublisher
    from .command_listener import CommandListener
    from .parameter_manager import ParameterManager
except ImportError:
    from firebase_client import get_firestore_client, get_rtdb_root
    from robot_adapter import RealRobotAdapter, SimulatedRobotAdapter, RobotInterface
    from ftp_bridge import FTPBridge
    from dispatcher import CommandDispatcher
    from status_publisher import StatusPublisher
    from command_listener import CommandListener
    from parameter_manager import ParameterManager

logger = logging.getLogger(__name__)


@dataclass
class RobotConfig:
    """Robot configuration loaded from Firestore."""
    robot_id: str
    ip_address: str
    tcp_port: int
    ftp_user: str
    ftp_password: str
    controller: str
    model: str
    simulation: bool
    name: str = ""
    
    @classmethod
    def from_firestore(cls, robot_id: str, data: Dict[str, Any]) -> "RobotConfig":
        """Create RobotConfig from Firestore document data."""
        return cls(
            robot_id=robot_id,
            ip_address=data.get("ipAddress", "192.168.0.20"),
            tcp_port=data.get("tcpPort", 18735),
            ftp_user=data.get("ftpUser", "anonymous"),
            ftp_password=data.get("ftpPassword", ""),
            controller=data.get("controller", "R-30iB"),
            model=data.get("model", "Unknown"),
            simulation=data.get("simulation", False),
            name=data.get("name", robot_id),
        )


class RobotSession:
    """Manages a single robot session with all its components."""
    
    def __init__(
        self,
        device_id: str,
        robot_config: RobotConfig,
        status_interval: float = 0.2,
    ):
        """Initialize robot session.
        
        Args:
            device_id: Device identifier
            robot_config: Robot configuration from Firestore
            status_interval: Status publishing interval in seconds
        """
        self.device_id = device_id
        self.robot_config = robot_config
        self.status_interval = status_interval
        
        # Components
        self.robot: Optional[RobotInterface] = None
        self.ftp_bridge: Optional[FTPBridge] = None
        self.parameter_manager: Optional[ParameterManager] = None
        self.dispatcher: Optional[CommandDispatcher] = None
        self.status_publisher: Optional[StatusPublisher] = None
        self.command_listener: Optional[CommandListener] = None
        
        logger.info(f"Initialized RobotSession for {robot_config.robot_id}")
    
    def start(self) -> None:
        """Start the robot session."""
        try:
            logger.info(f"Starting robot session: {self.robot_config.robot_id}")
            logger.info(f"  Mode: {'SIMULATION' if self.robot_config.simulation else 'REAL'}")
            logger.info(f"  IP: {self.robot_config.ip_address}:{self.robot_config.tcp_port}")
            
            # Create robot adapter
            if self.robot_config.simulation:
                self.robot = SimulatedRobotAdapter()
            else:
                self.robot = RealRobotAdapter(
                    host=self.robot_config.ip_address,
                    port=self.robot_config.tcp_port,
                    ftp_user=self.robot_config.ftp_user,
                    ftp_password=self.robot_config.ftp_password,
                    ee_do_type="RDO",
                    ee_do_num=7,
                )
            
            # Connect to robot
            code, msg = self.robot.connect()
            if code != 0:
                raise RuntimeError(f"Failed to connect to robot: {msg}")
            logger.info(f"✓ Connected to robot: {msg}")
            
            # Create FTP bridge
            self.ftp_bridge = FTPBridge(
                host=self.robot_config.ip_address,
                user=self.robot_config.ftp_user,
                password=self.robot_config.ftp_password,
                simulation=self.robot_config.simulation,
            )
            
            # Create parameter manager
            self.parameter_manager = ParameterManager(
                device_id=self.device_id,
                robot_id=self.robot_config.robot_id
            )
            
            # Load parameter definitions and initialize RTDB
            self.parameter_manager.load_definitions()
            self.parameter_manager.initialize_rtdb_parameters()
            
            # Create dispatcher
            self.dispatcher = CommandDispatcher(
                robot=self.robot,
                ftp_bridge=self.ftp_bridge,
                parameter_manager=self.parameter_manager,
            )
            
            # Get RTDB root
            rtdb_root = get_rtdb_root()
            
            # Create and start status publisher
            self.status_publisher = StatusPublisher(
                device_id=self.device_id,
                robot_id=self.robot_config.robot_id,
                robot=self.robot,
                rtdb_root=rtdb_root,
                interval=self.status_interval,
            )
            self.status_publisher.start()
            
            # Create and start command listener
            self.command_listener = CommandListener(
                device_id=self.device_id,
                robot_id=self.robot_config.robot_id,
                dispatcher=self.dispatcher,
                rtdb_root=rtdb_root,
            )
            self.command_listener.start()
            
            logger.info(f"✓ Robot session started: {self.robot_config.robot_id}")
            
        except Exception as e:
            logger.error(f"Failed to start robot session: {e}", exc_info=True)
            self.stop()
            raise
    
    def stop(self) -> None:
        """Stop the robot session."""
        logger.info(f"Stopping robot session: {self.robot_config.robot_id}")
        
        # Stop command listener
        if self.command_listener:
            try:
                self.command_listener.stop()
            except Exception as e:
                logger.error(f"Error stopping command listener: {e}")
        
        # Stop status publisher
        if self.status_publisher:
            try:
                self.status_publisher.stop()
            except Exception as e:
                logger.error(f"Error stopping status publisher: {e}")
        
        # Disconnect from robot
        if self.robot:
            try:
                self.robot.disconnect()
            except Exception as e:
                logger.error(f"Error disconnecting from robot: {e}")
        
        logger.info(f"✓ Robot session stopped: {self.robot_config.robot_id}")


class RobotSessionManager:
    """Manages robot sessions based on selectedRobotId in RTDB."""
    
    def __init__(self, device_id: str, status_interval: float = 0.2):
        """Initialize robot session manager.
        
        Args:
            device_id: Device identifier
            status_interval: Status publishing interval in seconds
        """
        self.device_id = device_id
        self.status_interval = status_interval
        
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._current_session: Optional[RobotSession] = None
        self._current_robot_id: Optional[str] = None
        
        logger.info(f"Initialized RobotSessionManager for device: {device_id}")
    
    def start(self) -> None:
        """Start watching for selectedRobotId changes."""
        if self._running:
            logger.warning("RobotSessionManager already running")
            return
        
        self._running = True
        self._thread = threading.Thread(target=self._watch_loop, daemon=True)
        self._thread.start()
        
        logger.info("RobotSessionManager started")
    
    def stop(self) -> None:
        """Stop the session manager."""
        if not self._running:
            return
        
        logger.info("Stopping RobotSessionManager...")
        
        self._running = False
        
        if self._thread:
            self._thread.join(timeout=5.0)
        
        # Stop current session if any
        if self._current_session:
            self._current_session.stop()
            self._current_session = None
        
        logger.info("RobotSessionManager stopped")
    
    def _watch_loop(self) -> None:
        """Main loop watching for selectedRobotId changes."""
        logger.info("RobotSessionManager watch loop started")
        
        while self._running:
            try:
                self._check_selected_robot()
            except Exception as e:
                logger.error(f"Error in watch loop: {e}", exc_info=True)
            
            # Check every 2 seconds
            time.sleep(2)
        
        logger.info("RobotSessionManager watch loop ended")
    
    def _check_selected_robot(self) -> None:
        """Check if selectedRobotId has changed."""
        try:
            rtdb_root = get_rtdb_root()
            selected_robot_ref = rtdb_root.child(f"devices/{self.device_id}/selectedRobotId")
            
            selected_robot_id = selected_robot_ref.get()
            
            # Check if selection changed
            if selected_robot_id != self._current_robot_id:
                logger.info(f"Selected robot changed: {self._current_robot_id} → {selected_robot_id}")
                
                # Stop current session
                if self._current_session:
                    logger.info("Stopping current robot session...")
                    self._current_session.stop()
                    self._current_session = None
                
                # Start new session if robot is selected
                if selected_robot_id:
                    logger.info(f"Starting new robot session: {selected_robot_id}")
                    self._start_robot_session(selected_robot_id)
                else:
                    logger.info("No robot selected, waiting...")
                
                self._current_robot_id = selected_robot_id
                
        except Exception as e:
            logger.error(f"Error checking selected robot: {e}", exc_info=True)
    
    def _start_robot_session(self, robot_id: str) -> None:
        """Start a new robot session.
        
        Args:
            robot_id: Robot identifier from Firestore
        """
        try:
            # Load robot configuration from Firestore
            robot_config = self._load_robot_config(robot_id)
            
            # Create and start session
            self._current_session = RobotSession(
                device_id=self.device_id,
                robot_config=robot_config,
                status_interval=self.status_interval,
            )
            self._current_session.start()
            
        except Exception as e:
            logger.error(f"Failed to start robot session: {e}", exc_info=True)
            self._current_session = None
            raise
    
    def _load_robot_config(self, robot_id: str) -> RobotConfig:
        """Load robot configuration from Firestore.
        
        Args:
            robot_id: Robot identifier
            
        Returns:
            RobotConfig object
            
        Raises:
            RuntimeError: If robot document doesn't exist
        """
        try:
            firestore_client = get_firestore_client()
            robot_ref = firestore_client.collection('robots').document(robot_id)
            robot_doc = robot_ref.get()
            
            if not robot_doc.exists:
                raise RuntimeError(f"Robot document not found: {robot_id}")
            
            robot_data = robot_doc.to_dict()
            robot_config = RobotConfig.from_firestore(robot_id, robot_data)
            
            logger.info(f"✓ Loaded robot config: {robot_config.name}")
            logger.info(f"  IP: {robot_config.ip_address}:{robot_config.tcp_port}")
            logger.info(f"  Controller: {robot_config.controller}")
            logger.info(f"  Simulation: {robot_config.simulation}")
            
            return robot_config
            
        except Exception as e:
            logger.error(f"Failed to load robot config: {e}", exc_info=True)
            raise

