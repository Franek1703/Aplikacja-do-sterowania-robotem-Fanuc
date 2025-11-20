#!/usr/bin/env python3
"""
Test script to verify device registration in both Firestore and Realtime Database.

This script:
1. Initializes Firebase
2. Registers a test device
3. Verifies the device exists in both Firestore and RTDB
4. Cleans up the test device
"""

import sys
import time
import logging
from datetime import datetime

try:
    from config import load_settings
    from firebase_client import initialize_firebase, get_firestore_client, get_rtdb_root
    from device_manager import DeviceManager
except ImportError:
    from fanuc_firebase_gateway.config import load_settings
    from fanuc_firebase_gateway.firebase_client import initialize_firebase, get_firestore_client, get_rtdb_root
    from fanuc_firebase_gateway.device_manager import DeviceManager

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def verify_firestore_device(device_id: str) -> bool:
    """Verify device exists in Firestore."""
    try:
        firestore_client = get_firestore_client()
        device_ref = firestore_client.collection('devices').document(device_id)
        device_doc = device_ref.get()
        
        if device_doc.exists:
            data = device_doc.to_dict()
            logger.info(f"✓ Device found in Firestore: {device_id}")
            logger.info(f"  - Name: {data.get('name')}")
            logger.info(f"  - Online: {data.get('online')}")
            logger.info(f"  - Last Seen: {data.get('lastSeen')}")
            logger.info(f"  - Firmware: {data.get('firmwareVersion')}")
            return True
        else:
            logger.error(f"✗ Device NOT found in Firestore: {device_id}")
            return False
    except Exception as e:
        logger.error(f"Error checking Firestore: {e}")
        return False


def verify_rtdb_device(device_id: str) -> bool:
    """Verify device exists in Realtime Database."""
    try:
        rtdb_root = get_rtdb_root()
        device_ref = rtdb_root.child(f"devices/{device_id}")
        device_data = device_ref.get()
        
        if device_data is not None:
            logger.info(f"✓ Device found in RTDB: {device_id}")
            status = device_data.get('status', {})
            logger.info(f"  - Online: {status.get('online')}")
            
            last_seen_ms = status.get('lastSeen')
            if last_seen_ms:
                last_seen_dt = datetime.fromtimestamp(last_seen_ms / 1000)
                logger.info(f"  - Last Seen: {last_seen_dt} ({last_seen_ms}ms)")
            
            return True
        else:
            logger.error(f"✗ Device NOT found in RTDB: {device_id}")
            return False
    except Exception as e:
        logger.error(f"Error checking RTDB: {e}")
        return False


def cleanup_device(device_id: str) -> None:
    """Remove test device from both databases."""
    try:
        # Remove from Firestore
        firestore_client = get_firestore_client()
        device_ref = firestore_client.collection('devices').document(device_id)
        device_ref.delete()
        logger.info(f"✓ Removed device from Firestore: {device_id}")
        
        # Remove from RTDB
        rtdb_root = get_rtdb_root()
        device_ref = rtdb_root.child(f"devices/{device_id}")
        device_ref.delete()
        logger.info(f"✓ Removed device from RTDB: {device_id}")
        
    except Exception as e:
        logger.error(f"Error during cleanup: {e}")


def main():
    """Main test function."""
    logger.info("=" * 60)
    logger.info("Device Registration Test")
    logger.info("=" * 60)
    
    # Load settings and initialize Firebase
    try:
        settings = load_settings()
        initialize_firebase(settings.firebase_service_account, settings.firebase_rtdb_url)
        logger.info("✓ Firebase initialized")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        sys.exit(1)
    
    device_id = settings.device_id
    logger.info(f"Testing with device ID: {device_id}")
    logger.info("")
    
    # Create device manager and register device
    logger.info("Step 1: Registering device...")
    try:
        device_manager = DeviceManager(device_id)
        device_manager.ensure_device_registered()
        logger.info("✓ Device registration completed")
    except Exception as e:
        logger.error(f"Failed to register device: {e}")
        sys.exit(1)
    
    logger.info("")
    
    # Verify in Firestore
    logger.info("Step 2: Verifying Firestore...")
    firestore_ok = verify_firestore_device(device_id)
    logger.info("")
    
    # Verify in RTDB
    logger.info("Step 3: Verifying Realtime Database...")
    rtdb_ok = verify_rtdb_device(device_id)
    logger.info("")
    
    # Test heartbeat update
    logger.info("Step 4: Testing heartbeat update...")
    try:
        logger.info("Starting heartbeat (will run for 5 seconds)...")
        device_manager.start_heartbeat()
        time.sleep(5)
        device_manager.stop_heartbeat()
        logger.info("✓ Heartbeat test completed")
    except Exception as e:
        logger.error(f"Heartbeat test failed: {e}")
    
    logger.info("")
    
    # Verify updates after heartbeat
    logger.info("Step 5: Verifying updates after heartbeat...")
    firestore_ok_2 = verify_firestore_device(device_id)
    rtdb_ok_2 = verify_rtdb_device(device_id)
    logger.info("")
    
    # Summary
    logger.info("=" * 60)
    logger.info("Test Summary")
    logger.info("=" * 60)
    logger.info(f"Firestore Registration: {'✓ PASS' if firestore_ok else '✗ FAIL'}")
    logger.info(f"RTDB Registration:      {'✓ PASS' if rtdb_ok else '✗ FAIL'}")
    logger.info(f"Firestore Update:       {'✓ PASS' if firestore_ok_2 else '✗ FAIL'}")
    logger.info(f"RTDB Update:            {'✓ PASS' if rtdb_ok_2 else '✗ FAIL'}")
    logger.info("=" * 60)
    
    # Ask if user wants to clean up
    logger.info("")
    response = input("Do you want to remove the test device? (y/N): ").strip().lower()
    if response == 'y':
        cleanup_device(device_id)
        logger.info("✓ Cleanup completed")
    else:
        logger.info("Skipping cleanup. Device remains in databases.")
    
    # Exit with appropriate code
    all_passed = firestore_ok and rtdb_ok and firestore_ok_2 and rtdb_ok_2
    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()

