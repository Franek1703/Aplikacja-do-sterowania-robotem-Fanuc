"""
Main entry point for FANUC Firebase Gateway.

Runs as a long-running service on Raspberry Pi.
All robot configuration now comes from Firestore dynamically.
See firebase_protocol.md for complete protocol specification.
"""

import logging
import signal
import sys
import time
from typing import Optional

try:
    from .config import Settings, load_settings, setup_logging
    from .firebase_client import initialize_firebase
    from .device_manager import DeviceManager
    from .robot_session_manager import RobotSessionManager
except ImportError:
    from config import Settings, load_settings, setup_logging
    from firebase_client import initialize_firebase
    from device_manager import DeviceManager
    from robot_session_manager import RobotSessionManager

logger = logging.getLogger(__name__)


class FirebaseGateway:
    """Main gateway application with dynamic robot configuration."""
    
    def __init__(self, settings: Settings):
        """Initialize the gateway.
        
        Args:
            settings: Configuration settings (Firebase + operational only)
        """
        self.settings = settings
        self.device_manager: Optional[DeviceManager] = None
        self.session_manager: Optional[RobotSessionManager] = None
        self._running = False
        
        logger.info("Initializing FirebaseGateway")
        logger.info(f"  Device ID: {settings.device_id}")
    
    def setup(self) -> None:
        """Set up all components."""
        logger.info("Setting up FirebaseGateway components...")
        
        # Initialize Firebase
        initialize_firebase(self.settings)
        logger.info("✓ Firebase initialized")
        
        # Create and register device
        self.device_manager = DeviceManager(self.settings.device_id)
        self.device_manager.ensure_device_registered()
        logger.info("✓ Device registered in Firestore")
        
        # Create robot session manager
        self.session_manager = RobotSessionManager(
            device_id=self.settings.device_id,
            status_interval=self.settings.status_publish_interval,
        )
        logger.info("✓ Robot session manager created")
        
        logger.info("FirebaseGateway setup complete")
    
    def start(self) -> None:
        """Start the gateway."""
        logger.info("Starting FirebaseGateway...")
        
        self._running = True
        
        # Start device heartbeat
        self.device_manager.start_heartbeat()
        logger.info("✓ Device heartbeat started")
        
        # Start robot session manager (watches for selectedRobotId)
        self.session_manager.start()
        logger.info("✓ Robot session manager started")
        
        logger.info("=" * 60)
        logger.info("FirebaseGateway started successfully")
        logger.info("=" * 60)
        logger.info("")
        logger.info("Waiting for robot selection from mobile app...")
        logger.info(f"Set /devices/{self.settings.device_id}/selectedRobotId in RTDB")
        logger.info("")
    
    def stop(self) -> None:
        """Stop the gateway."""
        if not self._running:
            return
        
        logger.info("Stopping FirebaseGateway...")
        
        self._running = False
        
        # Stop robot session manager
        if self.session_manager:
            self.session_manager.stop()
        
        # Stop device heartbeat
        if self.device_manager:
            self.device_manager.stop_heartbeat()
        
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
    logger.info("FANUC Firebase Gateway v2.0")
    logger.info("=" * 60)
    logger.info(f"Device ID: {settings.device_id} (auto-generated from MAC)")
    logger.info(f"Status Interval: {settings.status_publish_interval}s")
    logger.info(f"Log Level: {settings.log_level}")
    logger.info("=" * 60)
    logger.info("Note: Robot configuration loaded dynamically from Firestore")
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

