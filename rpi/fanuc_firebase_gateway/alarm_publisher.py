"""
Alarm publisher.

Periodically reads alarm logs from robot via FTP and publishes to Firebase.
- Active alarms → RTDB: /devices/{deviceId}/robots/{robotId}/alarms/active/{alarmId}
- Alarm history → Firestore: /robotAlarms/{alarmEventId}
See firebase_protocol.md section 7 for data structure.
"""

import logging
import time
import threading
from typing import Optional, Dict, Set
from datetime import datetime

from firebase_admin import db, firestore

try:
    from .ftp_bridge import FTPBridge
    from .models import Alarm
except ImportError:
    from ftp_bridge import FTPBridge
    from models import Alarm

logger = logging.getLogger(__name__)


class AlarmPublisher:
    """Publishes robot alarms to Firebase RTDB and Firestore.
    
    Runs in a separate thread and updates alarms at regular intervals.
    Reads active alarms (ERRACT.LS) and all alarms (ERRALL.LS) from robot via FTP.
    """
    
    def __init__(
        self,
        device_id: str,
        robot_id: str,
        ftp_bridge: FTPBridge,
        rtdb_root: db.Reference,
        firestore_client: firestore.Client,
        interval: float = 5.0,
    ):
        """Initialize alarm publisher.
        
        Args:
            device_id: Device (Raspberry Pi) identifier
            robot_id: Robot identifier
            ftp_bridge: FTP bridge for reading alarm logs
            rtdb_root: Firebase RTDB root reference
            firestore_client: Firestore client for alarm history
            interval: Update interval in seconds (default: 5.0s)
        """
        self.device_id = device_id
        self.robot_id = robot_id
        self.ftp_bridge = ftp_bridge
        self.rtdb_root = rtdb_root
        self.firestore_client = firestore_client
        self.interval = interval
        
        self._running = False
        self._thread: Optional[threading.Thread] = None
        
        # Track published alarms to avoid duplicates
        self._published_active_alarm_ids: Set[str] = set()  # For RTDB active alarms
        self._published_history_event_ids: Set[str] = set()  # For Firestore history
        
        # RTDB references
        self.device_ref = rtdb_root.child(f"devices/{device_id}")
        self.robot_ref = self.device_ref.child(f"robots/{robot_id}")
        self.active_alarms_ref = self.robot_ref.child("alarms/active")
        
        # Firestore collection
        self.firestore_collection = firestore_client.collection("robotAlarms")
        
        logger.info(f"Initialized AlarmPublisher for device={device_id}, robot={robot_id}")
    
    def start(self) -> None:
        """Start the alarm publisher thread."""
        if self._running:
            logger.warning("AlarmPublisher already running")
            return
        
        self._running = True
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()
        
        logger.info("AlarmPublisher started")
    
    def stop(self) -> None:
        """Stop the alarm publisher thread."""
        if not self._running:
            return
        
        self._running = False
        
        if self._thread:
            self._thread.join(timeout=5.0)
        
        logger.info("AlarmPublisher stopped")
    
    def _run_loop(self) -> None:
        """Main loop for alarm publishing."""
        logger.info("AlarmPublisher loop started")
        
        while self._running:
            try:
                self._publish_alarms()
            except Exception as e:
                logger.error(f"Error publishing alarms: {e}", exc_info=True)
            
            # Sleep for the configured interval
            time.sleep(self.interval)
        
        logger.info("AlarmPublisher loop ended")
    
    def _publish_alarms(self) -> None:
        """Read alarms from robot and publish to Firebase.
        
        Reads:
        - ERRACT.LS for active/current alarms → RTDB
        - ERRALL.LS for all alarms → Firestore (history)
        """
        try:
            # Read active alarms (current alarms)
            active_alarms = self._read_active_alarms()
            
            # Publish active alarms to RTDB
            self._publish_active_alarms(active_alarms)
            
            # Read all alarms for history
            all_alarms = self._read_all_alarms()
            
            # Publish new alarms to Firestore history
            self._publish_alarm_history(all_alarms)
            
            logger.debug(f"Published {len(active_alarms)} active alarms, {len(all_alarms)} total alarms")
            
        except Exception as e:
            logger.error(f"Error in _publish_alarms: {e}", exc_info=True)
    
    def _read_active_alarms(self) -> list:
        """Read active/current alarms from robot via FTP.
        
        Returns:
            List of Alarm objects from ERRACT.LS
        """
        try:
            # Import AlarmLogType
            import sys
            from pathlib import Path
            fanuc_package_src = Path(__file__).parent.parent.parent / "fanuc_package" / "src"
            if str(fanuc_package_src) not in sys.path:
                sys.path.insert(0, str(fanuc_package_src))
            
            from robot.ftp import AlarmLogType
            
            # Use FTPBridge method to read alarms
            alarms = self.ftp_bridge.read_alarm_logs(kind=AlarmLogType.ACT)
            return alarms
        except Exception as e:
            logger.error(f"Error reading active alarms: {e}", exc_info=True)
            return []
    
    def _read_all_alarms(self) -> list:
        """Read all alarms from robot via FTP.
        
        Returns:
            List of Alarm objects from ERRALL.LS
        """
        try:
            # Import AlarmLogType
            import sys
            from pathlib import Path
            fanuc_package_src = Path(__file__).parent.parent.parent / "fanuc_package" / "src"
            if str(fanuc_package_src) not in sys.path:
                sys.path.insert(0, str(fanuc_package_src))
            
            from robot.ftp import AlarmLogType
            
            # Use FTPBridge method to read alarms
            alarms = self.ftp_bridge.read_alarm_logs(kind=AlarmLogType.ALL)
            return alarms
        except Exception as e:
            logger.error(f"Error reading all alarms: {e}", exc_info=True)
            return []
    
    def _convert_robot_alarm_to_firebase(self, robot_alarm, is_active: bool = True) -> Alarm:
        """Convert robot Alarm object to Firebase Alarm model.
        
        Args:
            robot_alarm: Alarm object from robot.alarm_parser
            is_active: Whether this is an active alarm
            
        Returns:
            Alarm model for Firebase
        """
        # Create unique alarm ID: alarm_number + alarm_code
        alarm_id = f"{robot_alarm.alarm_number}_{robot_alarm.alarm_code}"
        
        # Convert timestamp to Unix timestamp
        # Handle None timestamp by using current time
        if robot_alarm.timestamp:
            timestamp = int(robot_alarm.timestamp.timestamp())
        else:
            timestamp = int(time.time())
            logger.warning(f"Alarm {alarm_id} has no timestamp, using current time")
        
        return Alarm(
            alarmId=alarm_id,
            alarmCode=robot_alarm.alarm_code,
            message=robot_alarm.message,
            severity=robot_alarm.severity,
            timestamp=timestamp,
            causeMessage=robot_alarm.cause_message if robot_alarm.cause_message else None,
            actionRequired=robot_alarm.action_required if robot_alarm.action_required else None,
            flags=robot_alarm.flags if robot_alarm.flags else None,
            isActive=is_active
        )
    
    def _publish_active_alarms(self, active_alarms: list) -> None:
        """Publish active alarms to RTDB.
        
        Args:
            active_alarms: List of Alarm objects from robot
        """
        try:
            # Convert to Firebase Alarm models
            firebase_alarms: Dict[str, Dict] = {}
            current_alarm_ids: Set[str] = set()
            
            for robot_alarm in active_alarms:
                firebase_alarm = self._convert_robot_alarm_to_firebase(robot_alarm, is_active=True)
                alarm_id = firebase_alarm.alarmId
                current_alarm_ids.add(alarm_id)
                
                firebase_alarms[alarm_id] = firebase_alarm.to_dict()
            
            # Update RTDB with current active alarms
            if firebase_alarms:
                self.active_alarms_ref.set(firebase_alarms)
            else:
                # Clear active alarms if none exist
                self.active_alarms_ref.set({})
            
            # Remove alarms that are no longer active
            removed_alarms = self._published_active_alarm_ids - current_alarm_ids
            for alarm_id in removed_alarms:
                self.active_alarms_ref.child(alarm_id).delete()
            
            # Update tracked alarm IDs
            self._published_active_alarm_ids = current_alarm_ids
            
            logger.debug(f"Published {len(firebase_alarms)} active alarms to RTDB")
            
        except Exception as e:
            logger.error(f"Error publishing active alarms: {e}", exc_info=True)
    
    def _publish_alarm_history(self, all_alarms: list) -> None:
        """Publish alarm history to Firestore.
        
        Only publishes alarms that haven't been published before.
        
        Args:
            all_alarms: List of Alarm objects from robot
        """
        try:
            new_alarms_count = 0
            
            for robot_alarm in all_alarms:
                firebase_alarm = self._convert_robot_alarm_to_firebase(robot_alarm, is_active=False)
                alarm_id = firebase_alarm.alarmId
                
                # Create unique event ID: robot_id + alarm_id + timestamp
                event_id = f"{self.robot_id}_{alarm_id}_{firebase_alarm.timestamp}"
                
                # Check if already published
                if event_id in self._published_history_event_ids:
                    continue
                
                # Add device and robot info
                alarm_data = firebase_alarm.to_dict()
                alarm_data['deviceId'] = self.device_id
                alarm_data['robotId'] = self.robot_id
                alarm_data['eventId'] = event_id
                
                # Write to Firestore
                self.firestore_collection.document(event_id).set(alarm_data)
                
                # Track published event
                self._published_history_event_ids.add(event_id)
                new_alarms_count += 1
            
            if new_alarms_count > 0:
                logger.debug(f"Published {new_alarms_count} new alarms to Firestore history")
            
        except Exception as e:
            logger.error(f"Error publishing alarm history: {e}", exc_info=True)
    
    def publish_once(self) -> None:
        """Publish alarms once (useful for testing)."""
        self._publish_alarms()

