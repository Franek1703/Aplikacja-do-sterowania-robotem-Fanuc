"""
Device Manager for auto-registration and management.

Handles automatic device registration in Firestore and periodic status updates.
"""

import logging
import time
import threading
from typing import Optional
from datetime import datetime

try:
    from .firebase_client import get_firestore_client, get_rtdb_root
except ImportError:
    from firebase_client import get_firestore_client, get_rtdb_root

logger = logging.getLogger(__name__)


class DeviceManager:
    """Manages device registration and status in Firestore and Realtime Database.
    
    Automatically registers the device on first run and maintains
    online status and lastSeen timestamp in both Firestore and RTDB.
    """
    
    def __init__(self, device_id: str):
        """Initialize device manager.
        
        Args:
            device_id: Unique device identifier (MAC-based)
        """
        self.device_id = device_id
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._update_interval = 30  # Update lastSeen every 30 seconds
        
        logger.info(f"Initialized DeviceManager for device: {device_id}")
    
    def ensure_device_registered(self) -> None:
        """Ensure device document exists in both Firestore and Realtime Database.
        
        Creates the device document if it doesn't exist with default values.
        Updates online status if it already exists.
        """
        try:
            # 1. Register in Firestore
            firestore_client = get_firestore_client()
            device_ref = firestore_client.collection('devices').document(self.device_id)
            
            # Check if device exists
            device_doc = device_ref.get()
            
            if not device_doc.exists:
                # Create new device document
                device_data = {
                    "name": f"RPi Gateway {self.device_id[-12:]}",
                    "description": "Auto-registered device",
                    "ownerUid": None,
                    "members": [],
                    "online": True,
                    "lastSeen": datetime.now(),
                    "firmwareVersion": "1.0.0",
                    "robotCount": 0,
                    "robots": [],
                    "createdAt": datetime.now(),
                }
                device_ref.set(device_data)
                logger.info(f"✓ Created new device document in Firestore: {self.device_id}")
            else:
                # Update existing device
                device_ref.update({
                    "online": True,
                    "lastSeen": datetime.now(),
                })
                logger.info(f"✓ Updated existing device in Firestore: {self.device_id}")
            
            # 2. Register in Realtime Database
            rtdb_root = get_rtdb_root()
            rtdb_device_ref = rtdb_root.child(f"devices/{self.device_id}")
            
            # Check if device exists in RTDB
            rtdb_device_data = rtdb_device_ref.get()
            
            if rtdb_device_data is None:
                # Create new device in RTDB
                rtdb_initial_data = {
                    "status": {
                        "online": True,
                        "lastSeen": int(time.time() * 1000)  # Unix timestamp in milliseconds
                    }
                }
                rtdb_device_ref.set(rtdb_initial_data)
                logger.info(f"✓ Created new device in RTDB: {self.device_id}")
            else:
                # Update existing device status in RTDB
                rtdb_device_ref.child("status").update({
                    "online": True,
                    "lastSeen": int(time.time() * 1000)
                })
                logger.info(f"✓ Updated existing device in RTDB: {self.device_id}")
                
        except Exception as e:
            logger.error(f"Failed to register device: {e}", exc_info=True)
            raise
    
    def start_heartbeat(self) -> None:
        """Start periodic heartbeat to update lastSeen timestamp."""
        if self._running:
            logger.warning("Heartbeat already running")
            return
        
        self._running = True
        self._thread = threading.Thread(target=self._heartbeat_loop, daemon=True)
        self._thread.start()
        
        logger.info("Device heartbeat started")
    
    def stop_heartbeat(self) -> None:
        """Stop the heartbeat thread."""
        if not self._running:
            return
        
        self._running = False
        
        if self._thread:
            self._thread.join(timeout=5.0)
        
        # Mark device as offline in both Firestore and RTDB
        try:
            # Update Firestore
            firestore_client = get_firestore_client()
            device_ref = firestore_client.collection('devices').document(self.device_id)
            device_ref.update({
                "online": False,
                "lastSeen": datetime.now(),
            })
            
            # Update RTDB
            rtdb_root = get_rtdb_root()
            rtdb_device_ref = rtdb_root.child(f"devices/{self.device_id}/status")
            rtdb_device_ref.update({
                "online": False,
                "lastSeen": int(time.time() * 1000)
            })
            
            logger.info("Device marked as offline in Firestore and RTDB")
        except Exception as e:
            logger.error(f"Failed to mark device offline: {e}")
        
        logger.info("Device heartbeat stopped")
    
    def _heartbeat_loop(self) -> None:
        """Main heartbeat loop."""
        logger.info("Heartbeat loop started")
        
        while self._running:
            try:
                self._update_status()
            except Exception as e:
                logger.error(f"Error in heartbeat: {e}", exc_info=True)
            
            # Sleep for the update interval
            time.sleep(self._update_interval)
        
        logger.info("Heartbeat loop ended")
    
    def _update_status(self) -> None:
        """Update device status in both Firestore and Realtime Database."""
        try:
            # Update Firestore
            firestore_client = get_firestore_client()
            device_ref = firestore_client.collection('devices').document(self.device_id)
            
            device_ref.update({
                "online": True,
                "lastSeen": datetime.now(),
            })
            
            # Update RTDB
            rtdb_root = get_rtdb_root()
            rtdb_device_ref = rtdb_root.child(f"devices/{self.device_id}/status")
            
            rtdb_device_ref.update({
                "online": True,
                "lastSeen": int(time.time() * 1000)  # Unix timestamp in milliseconds
            })
            
            logger.debug(f"Updated device status in Firestore and RTDB: {self.device_id}")
            
        except Exception as e:
            logger.error(f"Failed to update device status: {e}")
    
    def update_robot_count(self, count: int) -> None:
        """Update the robot count in Firestore.
        
        Args:
            count: Number of robots currently managed by this device
        """
        try:
            firestore_client = get_firestore_client()
            device_ref = firestore_client.collection('devices').document(self.device_id)
            
            device_ref.update({
                "robotCount": count,
                "lastSeen": datetime.now(),
            })
            
            logger.info(f"Updated robot count to {count}")
            
        except Exception as e:
            logger.error(f"Failed to update robot count: {e}")

