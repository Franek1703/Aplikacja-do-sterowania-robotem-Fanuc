"""
Main entry point for FANUC Firebase Gateway.

Runs as a long-running service on Raspberry Pi.
See firebase_protocol.md for complete protocol specification.
"""

import logging
import signal
import sys
import time
from typing import Optional

try:
    from .config import Settings, load_settings, setup_logging
    from .firebase_client import initialize_firebase, get_rtdb_root
    from .robot_adapter import RealRobotAdapter, SimulatedRobotAdapter, RobotInterface
    from .ftp_bridge import FTPBridge
    from .dispatcher import CommandDispatcher
    from .status_publisher import StatusPublisher
    from .command_listener import CommandListener
except ImportError:
    from config import Settings, load_settings, setup_logging
    from firebase_client import initialize_firebase, get_rtdb_root
    from robot_adapter import RealRobotAdapter, SimulatedRobotAdapter, RobotInterface
    from ftp_bridge import FTPBridge
    from dispatcher import CommandDispatcher
    from status_publisher import StatusPublisher
    from command_listener import CommandListener

logger = logging.getLogger(__name__)


class FirebaseGateway:
    """Main gateway application."""
    
    def __init__(self, settings: Settings):
        """Initialize the gateway.
        
        Args:
            settings: Configuration settings
        """
        self.settings = settings
        self.robot: Optional[RobotInterface] = None
        self.ftp_bridge: Optional[FTPBridge] = None
        self.dispatcher: Optional[CommandDispatcher] = None
        self.status_publisher: Optional[StatusPublisher] = None
        self.command_listener: Optional[CommandListener] = None
        self._running = False
        
        logger.info("Initializing FirebaseGateway")
    
    def setup(self) -> None:
        """Set up all components."""
        logger.info("Setting up FirebaseGateway components...")
        
        # Initialize Firebase
        initialize_firebase(self.settings)
        rtdb_root = get_rtdb_root()
        
        # Create robot adapter
        if self.settings.simulation_mode:
            logger.info("Using SimulatedRobotAdapter")
            self.robot = SimulatedRobotAdapter()
        else:
            logger.info("Using RealRobotAdapter")
            self.robot = RealRobotAdapter(
                host=self.settings.robot_host,
                port=self.settings.robot_port,
                ftp_user=self.settings.robot_ftp_user,
                ftp_password=self.settings.robot_ftp_password,
                ee_do_type="RDO",  # Could be configurable
                ee_do_num=7,       # Could be configurable
            )
        
        # Connect to robot
        logger.info("Connecting to robot...")
        code, msg = self.robot.connect()
        if code != 0:
            logger.error(f"Failed to connect to robot: {msg}")
            raise RuntimeError(f"Robot connection failed: {msg}")
        logger.info(f"Robot connected: {msg}")
        
        # Create FTP bridge
        self.ftp_bridge = FTPBridge(
            host=self.settings.robot_host,
            user=self.settings.robot_ftp_user,
            password=self.settings.robot_ftp_password,
            simulation=self.settings.simulation_mode,
        )
        
        # Create dispatcher
        self.dispatcher = CommandDispatcher(
            robot=self.robot,
            ftp_bridge=self.ftp_bridge,
        )
        
        # For now, use a default robot ID (could be configurable)
        robot_id = "robotA"
        
        # Create status publisher
        self.status_publisher = StatusPublisher(
            device_id=self.settings.device_id,
            robot_id=robot_id,
            robot=self.robot,
            rtdb_root=rtdb_root,
            interval=self.settings.status_publish_interval,
        )
        
        # Create command listener
        self.command_listener = CommandListener(
            device_id=self.settings.device_id,
            robot_id=robot_id,
            dispatcher=self.dispatcher,
            rtdb_root=rtdb_root,
        )
        
        logger.info("FirebaseGateway setup complete")
    
    def start(self) -> None:
        """Start the gateway."""
        logger.info("Starting FirebaseGateway...")
        
        self._running = True
        
        # Start status publisher
        self.status_publisher.start()
        
        # Start command listener
        self.command_listener.start()
        
        logger.info("FirebaseGateway started successfully")
    
    def stop(self) -> None:
        """Stop the gateway."""
        if not self._running:
            return
        
        logger.info("Stopping FirebaseGateway...")
        
        self._running = False
        
        # Stop command listener
        if self.command_listener:
            self.command_listener.stop()
        
        # Stop status publisher
        if self.status_publisher:
            self.status_publisher.stop()
        
        # Disconnect from robot
        if self.robot:
            try:
                self.robot.disconnect()
                logger.info("Disconnected from robot")
            except Exception as e:
                logger.error(f"Error disconnecting from robot: {e}")
        
        logger.info("FirebaseGateway stopped")
    
    def run(self) -> None:
        """Run the gateway (blocking)."""
        self.setup()
        self.start()
        
        # Set up signal handlers for graceful shutdown
        def signal_handler(signum, frame):
            logger.info(f"Received signal {signum}, shutting down...")
            self.stop()
            sys.exit(0)
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        
        logger.info("FirebaseGateway is running. Press Ctrl+C to stop.")
        
        # Keep the main thread alive
        try:
            while self._running:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Keyboard interrupt received")
            self.stop()


def main() -> None:
    """Main entry point."""
    # Load settings
    try:
        settings = load_settings()
    except Exception as e:
        print(f"Error loading settings: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Setup logging
    setup_logging(settings.log_level)
    
    logger.info("=" * 60)
    logger.info("FANUC Firebase Gateway")
    logger.info("=" * 60)
    logger.info(f"Device ID: {settings.device_id}")
    logger.info(f"Simulation Mode: {settings.simulation_mode}")
    logger.info(f"Robot Host: {settings.robot_host}:{settings.robot_port}")
    logger.info(f"Status Interval: {settings.status_publish_interval}s")
    logger.info("=" * 60)
    
    # Create and run gateway
    try:
        gateway = FirebaseGateway(settings)
        gateway.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()

