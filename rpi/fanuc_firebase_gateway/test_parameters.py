#!/usr/bin/env python3
"""
Test script for robot parameters functionality.

This script:
1. Initializes Firebase
2. Creates test parameter definitions in Firestore
3. Tests parameter commands (update, get, getAll)
4. Verifies parameter validation
"""

import sys
import time
import logging
from datetime import datetime, timezone

try:
    from config import load_settings
    from firebase_client import initialize_firebase, get_firestore_client, get_rtdb_root
    from parameter_manager import ParameterManager
except ImportError:
    from fanuc_firebase_gateway.config import load_settings
    from fanuc_firebase_gateway.firebase_client import initialize_firebase, get_firestore_client, get_rtdb_root
    from fanuc_firebase_gateway.parameter_manager import ParameterManager

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def create_test_parameter_definitions(robot_id: str):
    """Create test parameter definitions in Firestore."""
    logger.info("Creating test parameter definitions...")
    
    firestore_client = get_firestore_client()
    params_ref = firestore_client.collection('robots').document(robot_id).collection('parameters')
    
    # Parameter definitions as per firebase_parameters_setup.md
    test_params = [
        {
            "id": "1",
            "name": "FTP Password",
            "defaultValue": "",
            "type": "string",
            "category": "Network",
            "isLocked": False,
            "description": "FTP access password for robot file system"
        },
        {
            "id": "2",
            "name": "Override Speed",
            "defaultValue": 100,
            "type": "number",
            "unit": "%",
            "category": "Motion",
            "isLocked": False,
            "description": "Global speed override percentage",
            "minValue": 0,
            "maxValue": 100
        },
        {
            "id": "3",
            "name": "Auto Backup",
            "defaultValue": True,
            "type": "boolean",
            "category": "System",
            "isLocked": False,
            "description": "Automatic backup of programs"
        },
        {
            "id": "4",
            "name": "Controller IP",
            "defaultValue": "192.168.1.100",
            "type": "string",
            "category": "Network",
            "isLocked": False,
            "description": "Controller network IP address"
        },
    ]
    
    for param in test_params:
        param_id = param["id"]
        params_ref.document(param_id).set(param)
        logger.info(f"✓ Created parameter {param_id}: {param['name']}")
    
    logger.info(f"Created {len(test_params)} parameter definitions")


def test_parameter_manager(device_id: str, robot_id: str):
    """Test parameter manager functionality."""
    logger.info("=" * 60)
    logger.info("Testing Parameter Manager")
    logger.info("=" * 60)
    
    # Create parameter manager
    param_manager = ParameterManager(device_id, robot_id)
    
    # Test 1: Load definitions
    logger.info("\nTest 1: Loading parameter definitions...")
    definitions = param_manager.load_definitions()
    logger.info(f"✓ Loaded {len(definitions)} parameter definitions")
    for param_id, param_def in definitions.items():
        logger.info(f"  - {param_id}: {param_def.name} ({param_def.type}, {param_def.category})")
    
    # Test 2: Initialize RTDB
    logger.info("\nTest 2: Initializing RTDB parameters...")
    param_manager.initialize_rtdb_parameters()
    logger.info("✓ RTDB parameters initialized")
    
    # Test 3: Get all parameters
    logger.info("\nTest 3: Getting all parameters...")
    all_params = param_manager.get_all_parameters()
    logger.info(f"✓ Retrieved {len(all_params)} parameters")
    for param_id, param_value in all_params.items():
        logger.info(f"  - {param_id}: {param_value.value} (updated by {param_value.updatedBy})")
    
    # Test 4: Update a parameter
    logger.info("\nTest 4: Updating parameter '2' (Override Speed) to 75...")
    success = param_manager.update_parameter("2", 75, "test_user")
    if success:
        logger.info("✓ Parameter updated successfully")
        updated_param = param_manager.get_parameter("2")
        if updated_param:
            logger.info(f"  New value: {updated_param.value}")
    else:
        logger.error("✗ Failed to update parameter")
    
    # Test 5: Validation - try invalid value
    logger.info("\nTest 5: Testing validation (invalid value)...")
    is_valid, error_msg = param_manager.validate_parameter("2", 150)  # Above max
    if not is_valid:
        logger.info(f"✓ Validation correctly rejected: {error_msg}")
    else:
        logger.error("✗ Validation should have failed")
    
    # Test 6: Validation - try locked parameter
    logger.info("\nTest 6: Testing locked parameter...")
    # First, make parameter locked
    firestore_client = get_firestore_client()
    firestore_client.collection('robots').document(robot_id).collection('parameters').document("3").update({
        "isLocked": True
    })
    param_manager.load_definitions()  # Reload
    
    is_valid, error_msg = param_manager.validate_parameter("3", False)
    if not is_valid:
        logger.info(f"✓ Locked parameter correctly rejected: {error_msg}")
    else:
        logger.error("✗ Locked parameter should have been rejected")
    
    # Unlock it again
    firestore_client.collection('robots').document(robot_id).collection('parameters').document("3").update({
        "isLocked": False
    })


def test_parameter_commands(device_id: str, robot_id: str):
    """Test parameter commands via RTDB."""
    logger.info("\n" + "=" * 60)
    logger.info("Testing Parameter Commands via RTDB")
    logger.info("=" * 60)
    
    rtdb_root = get_rtdb_root()
    commands_ref = rtdb_root.child(f"devices/{device_id}/robots/{robot_id}/commands")
    
    # Test updateParameter command
    logger.info("\nSending updateParameter command...")
    cmd_id = f"test_param_update_{int(time.time())}"
    command = {
        "type": "updateParameter",
        "status": "pending",
        "createdAt": int(time.time() * 1000),
        "createdBy": "test_script",
        "payload": {
            "parameterId": "2",
            "value": 85,
            "updatedBy": "test_script"
        },
        "result": {
            "code": None,
            "message": None,
            "completedAt": None
        }
    }
    
    commands_ref.child(cmd_id).set(command)
    logger.info(f"✓ Command sent: {cmd_id}")
    logger.info("  Waiting for gateway to process...")
    time.sleep(3)
    
    # Check result
    result = commands_ref.child(cmd_id).get()
    if result and result.get('status') == 'success':
        logger.info("✓ Command completed successfully")
        logger.info(f"  Result: {result.get('result', {}).get('message')}")
    else:
        logger.warning(f"Command status: {result.get('status') if result else 'unknown'}")
    
    # Test getAllParameters command
    logger.info("\nSending getAllParameters command...")
    cmd_id = f"test_get_all_params_{int(time.time())}"
    command = {
        "type": "getAllParameters",
        "status": "pending",
        "createdAt": int(time.time() * 1000),
        "createdBy": "test_script",
        "payload": {},
        "result": {
            "code": None,
            "message": None,
            "completedAt": None
        }
    }
    
    commands_ref.child(cmd_id).set(command)
    logger.info(f"✓ Command sent: {cmd_id}")
    logger.info("  Waiting for gateway to process...")
    time.sleep(3)
    
    # Check result
    result = commands_ref.child(cmd_id).get()
    if result and result.get('status') == 'success':
        logger.info("✓ Command completed successfully")
        data = result.get('result', {}).get('data', {})
        params = data.get('parameters', {})
        logger.info(f"  Retrieved {len(params)} parameters")
    else:
        logger.warning(f"Command status: {result.get('status') if result else 'unknown'}")


def main():
    """Main test function."""
    logger.info("=" * 60)
    logger.info("Robot Parameters Test")
    logger.info("=" * 60)
    
    # Load settings and initialize Firebase
    try:
        settings = load_settings()
        initialize_firebase(settings)
        logger.info("✓ Firebase initialized")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        sys.exit(1)
    
    device_id = settings.device_id
    
    # Use test robot or ask user
    robot_id = input("\nEnter robot ID to test (or press Enter for 'test_robot'): ").strip()
    if not robot_id:
        robot_id = "test_robot"
    
    logger.info(f"Using device ID: {device_id}")
    logger.info(f"Using robot ID: {robot_id}")
    
    # Create test parameter definitions
    try:
        create_test_parameter_definitions(robot_id)
    except Exception as e:
        logger.error(f"Failed to create parameter definitions: {e}")
        sys.exit(1)
    
    # Test parameter manager
    try:
        test_parameter_manager(device_id, robot_id)
    except Exception as e:
        logger.error(f"Parameter manager test failed: {e}", exc_info=True)
    
    # Test parameter commands (requires gateway to be running)
    logger.info("\n" + "=" * 60)
    response = input("Test parameter commands via RTDB? (requires gateway running) (y/N): ").strip().lower()
    if response == 'y':
        try:
            test_parameter_commands(device_id, robot_id)
        except Exception as e:
            logger.error(f"Parameter commands test failed: {e}", exc_info=True)
    
    logger.info("\n" + "=" * 60)
    logger.info("Tests completed!")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()

