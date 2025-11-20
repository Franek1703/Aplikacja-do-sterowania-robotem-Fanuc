"""
FANUC Firebase Gateway Package

A Python package for bridging FANUC robots with Firebase (Firestore + Realtime Database).
Supports both real robot control and simulation mode for testing.

See firebase_protocol.md for the complete protocol specification.
"""

__version__ = "1.0.0"
__author__ = "FANUC Control Team"

from .config import Settings, load_settings
from .firebase_client import initialize_firebase, get_firestore_client, get_rtdb_root
from .robot_adapter import RobotInterface, RealRobotAdapter, SimulatedRobotAdapter

__all__ = [
    "Settings",
    "load_settings",
    "initialize_firebase",
    "get_firestore_client",
    "get_rtdb_root",
    "RobotInterface",
    "RealRobotAdapter",
    "SimulatedRobotAdapter",
]

