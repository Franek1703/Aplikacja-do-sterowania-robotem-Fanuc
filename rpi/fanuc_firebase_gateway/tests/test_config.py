"""Tests for configuration management."""

import os
import pytest
from pathlib import Path
import tempfile

from fanuc_firebase_gateway.config import Settings, load_settings


def test_settings_validation():
    """Test that Settings validates required fields."""
    # Create a temporary service account file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        f.write('{"test": "data"}')
        temp_file = f.name
    
    try:
        # Valid settings
        settings = Settings(
            firebase_service_account=temp_file,
            firebase_rtdb_url="https://test.firebaseio.com",
            device_id="test_device",
        )
        assert settings.device_id == "test_device"
        assert settings.simulation_mode is False
        
        # Missing service account
        with pytest.raises(ValueError, match="FIREBASE_SERVICE_ACCOUNT"):
            Settings(
                firebase_service_account="",
                firebase_rtdb_url="https://test.firebaseio.com",
                device_id="test_device",
            )
        
        # Missing RTDB URL
        with pytest.raises(ValueError, match="FIREBASE_RTDB_URL"):
            Settings(
                firebase_service_account=temp_file,
                firebase_rtdb_url="",
                device_id="test_device",
            )
        
        # Missing device ID
        with pytest.raises(ValueError, match="DEVICE_ID"):
            Settings(
                firebase_service_account=temp_file,
                firebase_rtdb_url="https://test.firebaseio.com",
                device_id="",
            )
    finally:
        # Clean up temp file
        os.unlink(temp_file)


def test_settings_file_not_found():
    """Test that Settings raises error for non-existent service account file."""
    with pytest.raises(FileNotFoundError):
        Settings(
            firebase_service_account="/nonexistent/file.json",
            firebase_rtdb_url="https://test.firebaseio.com",
            device_id="test_device",
        )


def test_settings_defaults():
    """Test default values in Settings."""
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        f.write('{"test": "data"}')
        temp_file = f.name
    
    try:
        settings = Settings(
            firebase_service_account=temp_file,
            firebase_rtdb_url="https://test.firebaseio.com",
            device_id="test_device",
        )
        
        assert settings.simulation_mode is False
        assert settings.status_publish_interval == 0.2
        assert settings.robot_host == "192.168.0.20"
        assert settings.robot_port == 18735
        assert settings.robot_ftp_user == "anonymous"
        assert settings.robot_ftp_password == ""
        assert settings.log_level == "INFO"
    finally:
        os.unlink(temp_file)


def test_load_settings_from_env(monkeypatch):
    """Test loading settings from environment variables."""
    # Create a temporary service account file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        f.write('{"test": "data"}')
        temp_file = f.name
    
    try:
        # Set environment variables
        monkeypatch.setenv("FIREBASE_SERVICE_ACCOUNT", temp_file)
        monkeypatch.setenv("FIREBASE_RTDB_URL", "https://test.firebaseio.com")
        monkeypatch.setenv("DEVICE_ID", "env_device")
        monkeypatch.setenv("SIMULATION", "1")
        monkeypatch.setenv("STATUS_PUBLISH_INTERVAL", "0.5")
        monkeypatch.setenv("ROBOT_HOST", "10.0.0.1")
        monkeypatch.setenv("ROBOT_PORT", "12345")
        monkeypatch.setenv("LOG_LEVEL", "DEBUG")
        
        settings = load_settings()
        
        assert settings.device_id == "env_device"
        assert settings.simulation_mode is True
        assert settings.status_publish_interval == 0.5
        assert settings.robot_host == "10.0.0.1"
        assert settings.robot_port == 12345
        assert settings.log_level == "DEBUG"
    finally:
        os.unlink(temp_file)

