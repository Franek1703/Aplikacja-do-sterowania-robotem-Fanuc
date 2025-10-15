"""
Test script for the RobotFTP module.
"""

import unittest
from typing import BinaryIO
from io import StringIO, BytesIO
from unittest.mock import MagicMock, patch

from fanuc_package.src.robot import RobotFTP, RobotFTPError

class TestRobotFTP(unittest.TestCase):
    """Test cases for the RobotFTP class."""

    @patch('robot.ftp.FTP')
    def test_connect_success(self, mock_ftp):
        """Test successful connection."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        # Execute
        client = RobotFTP("192.168.1.1", "user", "pass")
        result = client.connect()
        
        # Assert
        self.assertTrue(result)
        mock_ftp.assert_called_once_with("192.168.1.1", timeout=10)
        mock_ftp_instance.login.assert_called_once_with("user", "pass")

    @patch('robot.ftp.FTP')
    def test_connect_failure(self, mock_ftp):
        """Test connection failure."""
        # Setup
        mock_ftp.side_effect = Exception("Connection failed")
        
        # Execute & Assert
        client = RobotFTP("192.168.1.1")
        with self.assertRaises(RobotFTPError):
            client.connect()

    @patch('robot.ftp.FTP')
    def test_list_files(self, mock_ftp):
        """Test listing files."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        # Mock the FTP LIST command response
        def side_effect(cmd, callback):
            lines = [
                "-rw-r--r-- 1 user group 1000 Jan 1 12:00 PROGRAM1.TP",
                "-rw-r--r-- 1 user group 2000 Jan 1 12:01 PROGRAM2.LS",
                "-rw-r--r-- 1 user group 3000 Jan 1 12:02 PROGRAM3.KL",
            ]
            for line in lines:
                callback(line)
        
        mock_ftp_instance.retrlines.side_effect = side_effect
        
        # Execute
        client = RobotFTP("192.168.1.1")
        client.ftp = mock_ftp_instance  # Bypass connect
        result = client.list_files("MD:", "*", "ALL")
        
        # Assert
        self.assertEqual(len(result), 3)
        self.assertIn("PROGRAM1.TP", result)
        self.assertIn("PROGRAM2.LS", result)
        self.assertIn("PROGRAM3.KL", result)
        
        # Test filtering by type
        result = client.list_files("MD:", "*", "TP")
        self.assertEqual(len(result), 2)
        self.assertIn("PROGRAM1.TP", result)
        self.assertIn("PROGRAM2.LS", result)
        self.assertNotIn("PROGRAM3.KL", result)

    @patch('robot.ftp.FTP')
    def test_read_file(self, mock_ftp):
        """Test reading a file."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        # Mock the FTP RETR command response
        def side_effect(cmd, callback):
            lines = [
                "Line 1 of the program",
                "Line 2 of the program",
                "Line 3 of the program",
            ]
            for line in lines:
                callback(line)
        
        mock_ftp_instance.retrlines.side_effect = side_effect
        
        # Execute
        client = RobotFTP("192.168.1.1")
        client.ftp = mock_ftp_instance  # Bypass connect
        content = client.read_file("MD:", "PROGRAM.TP")
        
        # Assert
        expected = "Line 1 of the program\nLine 2 of the program\nLine 3 of the program"
        self.assertEqual(content, expected)

    @patch('robot.ftp.FTP')
    def test_pattern_matching(self, mock_ftp):
        """Test pattern matching functionality."""
        # Setup
        client = RobotFTP("192.168.1.1")
        
        # Test exact match
        self.assertTrue(client._match_pattern("PROGRAM.TP", "PROGRAM.TP"))
        self.assertFalse(client._match_pattern("PROGRAM.TP", "ANOTHER.TP"))
        
        # Test wildcard match
        self.assertTrue(client._match_pattern("PROGRAM.TP", "*"))
        
        # Test starts with
        self.assertTrue(client._match_pattern("PROGRAM.TP", "PRO*"))
        self.assertFalse(client._match_pattern("PROGRAM.TP", "OTHER*"))
        
        # Test ends with
        self.assertTrue(client._match_pattern("PROGRAM.TP", "*.TP"))
        self.assertFalse(client._match_pattern("PROGRAM.TP", "*.KL"))
        
        # Test contains
        self.assertTrue(client._match_pattern("PROGRAM.TP", "*GRAM*"))
        self.assertFalse(client._match_pattern("PROGRAM.TP", "*MISSING*"))


    @patch('robot.ftp.FTP')
    def test_write_file(self, mock_ftp):
        """Test writing a file."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        # Execute - String content
        client = RobotFTP("192.168.1.1")
        client.ftp = mock_ftp_instance  # Bypass connect
        result = client.write_file("MD:", "TEST.TP", "Test content")
        
        # Assert
        self.assertTrue(result)
        mock_ftp_instance.storbinary.assert_called()
        
        # Execute - Bytes content
        result = client.write_file("MD:", "TEST.BIN", b"Binary content")
        self.assertTrue(result)
        
        # Execute - File-like object
        file_obj = io.BytesIO(b"File object content")
        result = client.write_file("MD:", "TEST2.BIN", file_obj)
        self.assertTrue(result)

    @patch('robot.ftp.FTP')
    def test_write_text_file(self, mock_ftp):
        """Test writing a text file."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        # Execute
        client = RobotFTP("192.168.1.1")
        client.ftp = mock_ftp_instance  # Bypass connect
        result = client.write_text_file("MD:", "TEST.TP", "Line 1\nLine 2")
        
        # Assert
        self.assertTrue(result)
        mock_ftp_instance.storlines.assert_called()

    @patch('robot.ftp.FTP')
    def test_directory_operations(self, mock_ftp):
        """Test directory operations."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        # Execute
        client = RobotFTP("192.168.1.1")
        client.ftp = mock_ftp_instance  # Bypass connect
        
        # Test create_directory
        result = client.create_directory("TEST_DIR")
        self.assertTrue(result)
        mock_ftp_instance.mkd.assert_called_with("TEST_DIR")
        
        # Test remove_directory
        result = client.remove_directory("TEST_DIR")
        self.assertTrue(result)
        mock_ftp_instance.rmd.assert_called_with("TEST_DIR")
        
        # Test change_directory
        result = client.change_directory("NEW_DIR")
        self.assertTrue(result)
        mock_ftp_instance.cwd.assert_called_with("NEW_DIR")
        
        # Test get_pwd
        mock_ftp_instance.pwd.return_value = "/MD:/NEW_DIR"
        pwd = client.get_pwd()
        self.assertEqual(pwd, "/MD:/NEW_DIR")

    @patch('robot.ftp.FTP')
    def test_file_operations(self, mock_ftp):
        """Test file operations."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        # Execute
        client = RobotFTP("192.168.1.1")
        client.ftp = mock_ftp_instance  # Bypass connect
        
        # Test rename_file
        result = client.rename_file("OLD.TP", "NEW.TP")
        self.assertTrue(result)
        mock_ftp_instance.rename.assert_called_with("OLD.TP", "NEW.TP")
        
        # Test remove_file
        result = client.remove_file("TEST.TP")
        self.assertTrue(result)
        mock_ftp_instance.delete.assert_called_with("TEST.TP")
        
        # Test get_file_size
        mock_ftp_instance.size.return_value = 1024
        size = client.get_file_size("TEST.TP")
        self.assertEqual(size, 1024)

    @patch('robot.ftp.FTP')
    @patch('builtins.open')
    def test_download_binary_file(self, mock_open, mock_ftp):
        """Test downloading a binary file."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        mock_file = MagicMock()
        mock_open.return_value.__enter__.return_value = mock_file
        
        # Execute
        client = RobotFTP("192.168.1.1")
        client.ftp = mock_ftp_instance  # Bypass connect
        result = client.download_binary_file("REMOTE.TP", "LOCAL.TP")
        
        # Assert
        self.assertTrue(result)
        mock_ftp_instance.retrbinary.assert_called()
        mock_open.assert_called_with("LOCAL.TP", 'wb')

    @patch('robot.ftp.FTP')
    def test_error_handling(self, mock_ftp):
        """Test error handling for various operations."""
        # Setup
        mock_ftp_instance = MagicMock()
        mock_ftp.return_value = mock_ftp_instance
        
        # Make operations fail
        mock_ftp_instance.storbinary.side_effect = Exception("Failed to store file")
        mock_ftp_instance.mkd.side_effect = Exception("Failed to create directory")
        mock_ftp_instance.rmd.side_effect = Exception("Failed to remove directory")
        
        # Execute
        client = RobotFTP("192.168.1.1")
        client.ftp = mock_ftp_instance  # Bypass connect
        
        # Test write_file error
        with self.assertRaises(RobotFTPError):
            client.write_file("MD:", "TEST.TP", "Test content")
            
        # Test create_directory error
        with self.assertRaises(RobotFTPError):
            client.create_directory("TEST_DIR")
            
        # Test remove_directory error
        with self.assertRaises(RobotFTPError):
            client.remove_directory("TEST_DIR")


if __name__ == "__main__":
    unittest.main()