"""
Configuration management for the Firebase Gateway.

Reads settings from environment variables or .env file.
All robot configuration now comes from Firestore dynamically.
"""

import os
import uuid
from dataclasses import dataclass
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


def get_device_id() -> str:
    """Get unique device ID based on MAC address.
    
    Returns:
        Device ID in format: device_rpi_<mac_address>
    """
    try:
        return "device_rpi_d83addc7d57f"
        # Get MAC address as integer
        mac = uuid.getnode()
        # Convert to hex string without separators
        mac_hex = f"{mac:012x}"
        # Format as device ID
        device_id = f"device_rpi_{mac_hex}"
        return device_id
    except Exception as e:
        logger.error(f"Failed to get MAC address: {e}")
        # Fallback to a random UUID (not recommended for production)
        fallback_id = f"device_rpi_{uuid.uuid4().hex[:12]}"
        logger.warning(f"Using fallback device ID: {fallback_id}")
        return fallback_id


@dataclass
class Settings:
    """Configuration settings for the Firebase Gateway.
    
    All robot-specific configuration is now loaded from Firestore dynamically.
    The .env file only contains Firebase credentials and basic operational settings.
    
    Attributes:
        firebase_service_account: Path to Firebase service account JSON file
        firebase_rtdb_url: Firebase Realtime Database URL
        status_publish_interval: Seconds between status updates (default: 0.2s = 200ms)
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR)
        device_id: Auto-generated unique identifier based on MAC address
    """
    
    firebase_service_account: str
    firebase_rtdb_url: str
    status_publish_interval: float = 0.2
    log_level: str = "INFO"
    
    def __post_init__(self):
        """Validate settings after initialization."""
        if not self.firebase_service_account:
            raise ValueError("FIREBASE_SERVICE_ACCOUNT must be set")
        
        if not self.firebase_rtdb_url:
            raise ValueError("FIREBASE_RTDB_URL must be set")
        
        # Check if service account file exists
        service_account_path = Path(self.firebase_service_account)
        if not service_account_path.exists():
            raise FileNotFoundError(
                f"Firebase service account file not found: {self.firebase_service_account}"
            )
        
        # Validate status publish interval
        if self.status_publish_interval <= 0:
            raise ValueError("STATUS_PUBLISH_INTERVAL must be positive")
    
    @property
    def device_id(self) -> str:
        """Get the device ID based on MAC address."""
        return get_device_id()


def load_settings() -> Settings:
    """Load settings from environment variables.
    
    Supports reading from .env file if python-dotenv is available.
    Robot configuration is NO LONGER read from .env - it comes from Firestore.
    
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
    
    # Read settings from environment (Firebase + operational settings only)
    settings = Settings(
        firebase_service_account=os.getenv(
            "FIREBASE_SERVICE_ACCOUNT",
            "serviceAccountKey.json"
        ),
        firebase_rtdb_url=os.getenv(
            "FIREBASE_RTDB_URL",
            ""
        ),
        status_publish_interval=float(os.getenv("STATUS_PUBLISH_INTERVAL", "0.2")),
        log_level=os.getenv("LOG_LEVEL", "INFO").upper(),
    )
    
    logger.info(f"Loaded settings: device_id={settings.device_id}")
    
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

