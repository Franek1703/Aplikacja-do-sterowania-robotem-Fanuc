"""
Configuration management for the Firebase Gateway.

Reads settings from environment variables or .env file.
"""

import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
import logging

logger = logging.getLogger(__name__)


@dataclass
class Settings:
    """Configuration settings for the Firebase Gateway.
    
    Attributes:
        firebase_service_account: Path to Firebase service account JSON file
        firebase_rtdb_url: Firebase Realtime Database URL
        device_id: Unique identifier for this Raspberry Pi device
        simulation_mode: If True, use simulated robot instead of real hardware
        status_publish_interval: Seconds between status updates (default: 0.2s = 200ms)
        robot_host: IP address of FANUC robot controller
        robot_port: Port for robot socket communication
        robot_ftp_user: FTP username for robot
        robot_ftp_password: FTP password for robot
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
    """
    
    firebase_service_account: str
    firebase_rtdb_url: str
    device_id: str
    simulation_mode: bool = False
    status_publish_interval: float = 0.2
    robot_host: str = "192.168.0.20"
    robot_port: int = 18735
    robot_ftp_user: str = "anonymous"
    robot_ftp_password: str = ""
    log_level: str = "INFO"
    
    def __post_init__(self):
        """Validate settings after initialization."""
        if not self.firebase_service_account:
            raise ValueError("FIREBASE_SERVICE_ACCOUNT must be set")
        
        if not self.firebase_rtdb_url:
            raise ValueError("FIREBASE_RTDB_URL must be set")
        
        if not self.device_id:
            raise ValueError("DEVICE_ID must be set")
        
        # Check if service account file exists
        service_account_path = Path(self.firebase_service_account)
        if not service_account_path.exists():
            raise FileNotFoundError(
                f"Firebase service account file not found: {self.firebase_service_account}"
            )
        
        # Validate status publish interval
        if self.status_publish_interval <= 0:
            raise ValueError("STATUS_PUBLISH_INTERVAL must be positive")


def load_settings() -> Settings:
    """Load settings from environment variables.
    
    Supports reading from .env file if python-dotenv is available.
    
    Returns:
        Settings object with configuration
        
    Raises:
        ValueError: If required settings are missing
        FileNotFoundError: If service account file doesn't exist
    """
    # Try to load .env file if python-dotenv is available
    try:
        from dotenv import load_dotenv
        load_dotenv()
        logger.info("Loaded settings from .env file")
    except ImportError:
        logger.debug("python-dotenv not available, using environment variables only")
    
    # Read settings from environment
    settings = Settings(
        firebase_service_account=os.getenv(
            "FIREBASE_SERVICE_ACCOUNT",
            "serviceAccountKey.json"
        ),
        firebase_rtdb_url=os.getenv(
            "FIREBASE_RTDB_URL",
            ""
        ),
        device_id=os.getenv("DEVICE_ID", ""),
        simulation_mode=os.getenv("SIMULATION", "0").lower() in ("1", "true", "yes"),
        status_publish_interval=float(os.getenv("STATUS_PUBLISH_INTERVAL", "0.2")),
        robot_host=os.getenv("ROBOT_HOST", "192.168.0.20"),
        robot_port=int(os.getenv("ROBOT_PORT", "18735")),
        robot_ftp_user=os.getenv("ROBOT_FTP_USER", "anonymous"),
        robot_ftp_password=os.getenv("ROBOT_FTP_PASSWORD", ""),
        log_level=os.getenv("LOG_LEVEL", "INFO").upper(),
    )
    
    logger.info(f"Loaded settings: device_id={settings.device_id}, "
                f"simulation_mode={settings.simulation_mode}")
    
    return settings


def setup_logging(log_level: str = "INFO") -> None:
    """Configure logging for the application.
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
    """
    logging.basicConfig(
        level=getattr(logging, log_level),
        format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

