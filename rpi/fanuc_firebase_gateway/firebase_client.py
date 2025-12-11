"""
Firebase client initialization and access.

Provides singleton access to Firestore and Realtime Database clients.
"""

import logging
from typing import Optional
import firebase_admin
from firebase_admin import credentials, firestore, db

try:
    from .config import Settings
except ImportError:
    from config import Settings

logger = logging.getLogger(__name__)

# Global state for Firebase clients
_firebase_initialized = False
_firestore_client: Optional[firestore.Client] = None
_rtdb_root: Optional[db.Reference] = None


def initialize_firebase(settings: Settings) -> None:
    """Initialize Firebase Admin SDK.
    
    This should be called exactly once at application startup.
    
    Args:
        settings: Configuration settings with Firebase credentials
        
    Raises:
        ValueError: If Firebase is already initialized
        FileNotFoundError: If service account file doesn't exist
    """
    global _firebase_initialized, _firestore_client, _rtdb_root
    
    if _firebase_initialized:
        logger.warning("Firebase already initialized, skipping")
        return
    
    try:
        # Load service account credentials
        cred = credentials.Certificate(settings.firebase_service_account)
        
        # Initialize Firebase Admin SDK
        firebase_admin.initialize_app(cred, {
            'databaseURL': settings.firebase_rtdb_url
        })
        
        # Create clients
        _firestore_client = firestore.client()
        _rtdb_root = db.reference()
        
        _firebase_initialized = True
        
        logger.info(f"Firebase initialized successfully with RTDB URL: {settings.firebase_rtdb_url}")
        
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        raise


def get_firestore_client() -> firestore.Client:
    """Get the Firestore client instance.
    
    Returns:
        Firestore client
        
    Raises:
        RuntimeError: If Firebase hasn't been initialized
    """
    if not _firebase_initialized or _firestore_client is None:
        raise RuntimeError("Firebase not initialized. Call initialize_firebase() first.")
    
    return _firestore_client


def get_rtdb_root() -> db.Reference:
    """Get the Realtime Database root reference.
    
    Returns:
        RTDB root reference
        
    Raises:
        RuntimeError: If Firebase hasn't been initialized
    """
    if not _firebase_initialized or _rtdb_root is None:
        raise RuntimeError("Firebase not initialized. Call initialize_firebase() first.")
    
    return _rtdb_root


def is_initialized() -> bool:
    """Check if Firebase has been initialized.
    
    Returns:
        True if initialized, False otherwise
    """
    return _firebase_initialized

