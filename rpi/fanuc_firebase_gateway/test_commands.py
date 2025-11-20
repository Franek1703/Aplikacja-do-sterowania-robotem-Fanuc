#!/usr/bin/env python3
"""
Test script for sending commands to Firebase Realtime Database.

This script demonstrates how to send various robot commands through Firebase
and verify they are processed by the gateway.
"""

import sys
import time
import logging
from pathlib import Path

# Add current directory to path
sys.path.insert(0, str(Path(__file__).parent))

from config import load_settings
from firebase_client import initialize_firebase, get_rtdb_root

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def send_move_command(rtdb_root, device_id: str, robot_id: str):
    """Send a move command to the robot."""
    command_id = f"test_move_{int(time.time())}"
    command_ref = rtdb_root.child(
        f"devices/{device_id}/robots/{robot_id}/commands/{command_id}"
    )
    
    command = {
        "type": "move",
        "status": "pending",
        "createdAt": int(time.time()),
        "createdBy": "test_script",
        "payload": {
            "mode": "pose",
            "vals": [450.0, 0.0, 300.0, 180.0, 0.0, 90.0],
            "velocity": 20,
            "acceleration": 100,
            "cnt": 0,
            "linear": True
        },
        "result": {
            "code": None,
            "message": None,
            "completedAt": None
        }
    }
    
    command_ref.set(command)
    logger.info(f"✓ Sent move command: {command_id}")
    return command_id, command_ref


def send_jog_start_command(rtdb_root, device_id: str, robot_id: str):
    """Send a jog start command."""
    command_id = f"test_jog_{int(time.time())}"
    command_ref = rtdb_root.child(
        f"devices/{device_id}/robots/{robot_id}/commands/{command_id}"
    )
    
    command = {
        "type": "jogStart",
        "status": "pending",
        "createdAt": int(time.time()),
        "createdBy": "test_script",
        "payload": {
            "axis": "X",
            "direction": "+",
            "speed": 25,
            "step": 0.5
        },
        "result": {
            "code": None,
            "message": None,
            "completedAt": None
        }
    }
    
    command_ref.set(command)
    logger.info(f"✓ Sent jog start command: {command_id}")
    return command_id, command_ref


def send_get_power_command(rtdb_root, device_id: str, robot_id: str):
    """Send a get power consumption command."""
    command_id = f"test_power_{int(time.time())}"
    command_ref = rtdb_root.child(
        f"devices/{device_id}/robots/{robot_id}/commands/{command_id}"
    )
    
    command = {
        "type": "getPowerConsumption",
        "status": "pending",
        "createdAt": int(time.time()),
        "createdBy": "test_script",
        "payload": {},
        "result": {
            "code": None,
            "message": None,
            "completedAt": None
        }
    }
    
    command_ref.set(command)
    logger.info(f"✓ Sent power consumption command: {command_id}")
    return command_id, command_ref


def send_set_tool_command(rtdb_root, device_id: str, robot_id: str, tool_num: int = 2):
    """Send a set tool command."""
    command_id = f"test_tool_{int(time.time())}"
    command_ref = rtdb_root.child(
        f"devices/{device_id}/robots/{robot_id}/commands/{command_id}"
    )
    
    command = {
        "type": "setTool",
        "status": "pending",
        "createdAt": int(time.time()),
        "createdBy": "test_script",
        "payload": {
            "toolNumber": tool_num
        },
        "result": {
            "code": None,
            "message": None,
            "completedAt": None
        }
    }
    
    command_ref.set(command)
    logger.info(f"✓ Sent set tool command: {command_id}")
    return command_id, command_ref


def send_ftp_list_files(rtdb_root, device_id: str, robot_id: str):
    """Send an FTP list files request."""
    request_id = f"test_ftp_{int(time.time())}"
    request_ref = rtdb_root.child(
        f"devices/{device_id}/robots/{robot_id}/ftp/requests/{request_id}"
    )
    
    request = {
        "type": "listFiles",
        "status": "pending",
        "createdAt": int(time.time()),
        "createdBy": "test_script",
        "payload": {
            "device": "MD:",
            "pattern": "*.TP",
            "types": "TP"
        },
        "result": {
            "code": None,
            "message": None,
            "completedAt": None
        }
    }
    
    request_ref.set(request)
    logger.info(f"✓ Sent FTP list files request: {request_id}")
    return request_id, request_ref


def wait_for_command_completion(command_ref, timeout: int = 10):
    """Wait for a command to complete and return the result."""
    logger.info("  Waiting for command to complete...")
    
    start_time = time.time()
    while time.time() - start_time < timeout:
        command_data = command_ref.get()
        if command_data and command_data.get("status") in ["success", "error"]:
            status = command_data.get("status")
            result = command_data.get("result", {})
            
            if status == "success":
                logger.info(f"  ✓ Command completed successfully")
                logger.info(f"    Message: {result.get('message')}")
                if result.get('data'):
                    logger.info(f"    Data: {result.get('data')}")
                return True, result
            else:
                logger.warning(f"  ✗ Command failed")
                logger.warning(f"    Message: {result.get('message')}")
                return False, result
        
        time.sleep(0.5)
    
    logger.warning(f"  ⚠ Command timed out after {timeout}s")
    return False, None


def main():
    """Main test function."""
    logger.info("=" * 60)
    logger.info("FANUC Firebase Gateway - Command Test")
    logger.info("=" * 60)
    logger.info("")
    
    # Load settings
    try:
        settings = load_settings()
        logger.info(f"✓ Settings loaded")
        logger.info(f"  Device ID: {settings.device_id} (auto-generated from MAC)")
        logger.info(f"  RTDB URL: {settings.firebase_rtdb_url}")
    except Exception as e:
        logger.error(f"✗ Failed to load settings: {e}")
        return False
    
    # Initialize Firebase
    try:
        initialize_firebase(settings)
        rtdb_root = get_rtdb_root()
        logger.info(f"✓ Firebase initialized")
        logger.info("")
    except Exception as e:
        logger.error(f"✗ Failed to initialize Firebase: {e}")
        return False
    
    # Configuration
    device_id = settings.device_id
    
    # Get selected robot ID from RTDB
    try:
        selected_robot_ref = rtdb_root.child(f"devices/{device_id}/selectedRobotId")
        robot_id = selected_robot_ref.get()
        
        if not robot_id:
            logger.error("✗ No robot selected!")
            logger.error(f"  Please set /devices/{device_id}/selectedRobotId in Firebase RTDB")
            logger.error(f"  Example: Set it to your robot document ID from Firestore")
            return False
        
        logger.info(f"✓ Selected robot: {robot_id}")
        logger.info("")
    except Exception as e:
        logger.error(f"✗ Failed to get selected robot: {e}")
        return False
    
    logger.info("=" * 60)
    logger.info("Sending Test Commands")
    logger.info("=" * 60)
    logger.info("")
    
    # Test 1: Get Power Consumption (simple command)
    logger.info("Test 1: Get Power Consumption")
    try:
        cmd_id, cmd_ref = send_get_power_command(rtdb_root, device_id, robot_id)
        success, result = wait_for_command_completion(cmd_ref)
        logger.info("")
    except Exception as e:
        logger.error(f"  ✗ Error: {e}")
        logger.info("")
    
    # Test 2: Set Tool
    logger.info("Test 2: Set Tool Number")
    try:
        cmd_id, cmd_ref = send_set_tool_command(rtdb_root, device_id, robot_id, tool_num=2)
        success, result = wait_for_command_completion(cmd_ref)
        logger.info("")
    except Exception as e:
        logger.error(f"  ✗ Error: {e}")
        logger.info("")
    
    # Test 3: Move Command
    logger.info("Test 3: Move to Position")
    try:
        cmd_id, cmd_ref = send_move_command(rtdb_root, device_id, robot_id)
        success, result = wait_for_command_completion(cmd_ref)
        logger.info("")
    except Exception as e:
        logger.error(f"  ✗ Error: {e}")
        logger.info("")
    
    # Test 4: Jog Start
    logger.info("Test 4: Jog Start")
    try:
        cmd_id, cmd_ref = send_jog_start_command(rtdb_root, device_id, robot_id)
        success, result = wait_for_command_completion(cmd_ref)
        logger.info("")
    except Exception as e:
        logger.error(f"  ✗ Error: {e}")
        logger.info("")
    
    # Test 5: FTP List Files
    logger.info("Test 5: FTP List Files")
    try:
        req_id, req_ref = send_ftp_list_files(rtdb_root, device_id, robot_id)
        success, result = wait_for_command_completion(req_ref)
        
        # Also check response path
        response_ref = rtdb_root.child(
            f"devices/{device_id}/robots/{robot_id}/ftp/responses/{req_id}"
        )
        response_data = response_ref.get()
        if response_data:
            logger.info(f"  ✓ FTP response received")
            if response_data.get('result', {}).get('data', {}).get('files'):
                files = response_data['result']['data']['files']
                logger.info(f"    Found {len(files)} files")
        logger.info("")
    except Exception as e:
        logger.error(f"  ✗ Error: {e}")
        logger.info("")
    
    logger.info("=" * 60)
    logger.info("Test Complete")
    logger.info("=" * 60)
    logger.info("")
    logger.info("Check Firebase Console → Realtime Database to see:")
    logger.info(f"  /devices/{device_id}/robots/{robot_id}/commands/")
    logger.info(f"  /devices/{device_id}/robots/{robot_id}/ftp/")
    logger.info("")
    logger.info("Make sure the gateway is running to process these commands!")
    logger.info("")
    
    return True


if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        logger.info("\nTest interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        sys.exit(1)

