"""
FTP client for Fanuc robots.

This module provides functionality to connect, list and read files from a Fanuc robot's FTP server.
It also supports file and directory operations like creating, removing, and renaming files and directories.
"""

from ftplib import FTP, error_perm, error_temp
import logging
import os
from typing import List, Optional, BinaryIO, Union
from io import StringIO, BytesIO

# Setup logging
logger = logging.getLogger(__name__)


class RobotFTPError(Exception):
    """Base exception for RobotFTP errors."""
    pass


class RobotFTP:
    """FTP client for Fanuc robots.
    
    This class provides methods to connect to a Fanuc robot's FTP server,
    list files and directories, and read file contents.
    """
    
    # Mapping of file extensions to their types
    EXTENSION_TO_TYPE = {
        '.TP': 'TP',      # TP program files
        '.LS': 'TP',      # TP program files (older format)
        '.PC': 'TP',      # TP program control files
        '.KL': 'KAREL',   # KAREL program files
    }
    
    def __init__(self, host: str, user: str = "anonymous", password: str = ""):
        """Initialize the RobotFTP client.
        
        Args:
            host: IP address or hostname of the robot.
            user: FTP username, defaults to "anonymous".
            password: FTP password, defaults to empty string.
        """
        self.host = host
        self.user = user
        self.password = password
        self.ftp: Optional[FTP] = None
        
    def connect(self) -> bool:
        """Connect to the robot's FTP server.
        
        Returns:
            True if connection was successful, False otherwise.
            
        Raises:
            RobotFTPError: If connection fails.
        """
        try:
            self.ftp = FTP(self.host, timeout=10)
            self.ftp.login(self.user, self.password)
            logger.info(f"Connected to FTP server at {self.host}")
            return True
        except (error_perm, error_temp, OSError) as e:
            logger.error(f"Failed to connect to FTP server: {e}")
            raise RobotFTPError(f"FTP connection failed: {e}")
    
    def disconnect(self) -> None:
        """Disconnect from the FTP server."""
        if self.ftp and self.ftp.sock:
            try:
                self.ftp.quit()
                logger.info("Disconnected from FTP server")
            except Exception as e:
                logger.warning(f"Error during FTP disconnect: {e}")
            finally:
                self.ftp = None
    
    def _ensure_connected(self) -> None:
        """Ensure FTP connection is established.
        
        Raises:
            RobotFTPError: If not connected.
        """
        if not self.ftp or not self.ftp.sock:
            raise RobotFTPError("Not connected to FTP server. Call connect() first.")
    
    def list_files(self, device: str = "MD:", pattern: str = "*", types: str = "ALL") -> List[str]:
        """List files on the robot's FTP server.
        
        Args:
            device: Device to list files from (e.g., "MD:", "UD1:"), defaults to "MD:".
            pattern: File pattern to match, defaults to "*".
            types: Type of files to list ("TP", "KAREL", or "ALL"), defaults to "ALL".
            
        Returns:
            A list of filenames.
            
        Raises:
            RobotFTPError: If listing fails.
        """
        self._ensure_connected()
        
        # Make sure device has a colon at the end
        if not device.endswith(':'):
            device = f"{device}:"
        
        try:
            # Change to the requested device
            self.ftp.cwd(device)
            
            # Get the raw file listing
            file_list = []
            self.ftp.retrlines("LIST", file_list.append)
            
            # Process the file listing
            result = []
            for line in file_list:
                # Example line: "-rw-r--r-- 1 user group 12345 Jan 1 12:00 PROGRAM.TP"
                parts = line.split()
                if len(parts) < 9:  # Typical FTP LIST format has at least 9 parts
                    continue
                
                filename = parts[8]  # Filename is usually the 9th element
                
                # Check if it matches the requested pattern
                if not self._match_pattern(filename, pattern):
                    continue
                
                # Filter by file type if specified
                if types != "ALL":
                    ext = os.path.splitext(filename)[1].upper()
                    if ext in self.EXTENSION_TO_TYPE and self.EXTENSION_TO_TYPE[ext] != types:
                        continue
                
                result.append(filename)
            
            logger.info(f"Listed {len(result)} files on {device}")
            return result
            
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to list files: {e}")
            raise RobotFTPError(f"Failed to list files: {e}")
    
    def _match_pattern(self, filename: str, pattern: str) -> bool:
        """Check if filename matches the given pattern.
        
        Args:
            filename: The filename to check.
            pattern: The pattern to match (using simple * wildcards).
            
        Returns:
            True if the filename matches the pattern, False otherwise.
        """
        # Convert the glob-style pattern to a simple match logic
        if pattern == "*":
            return True
        
        if pattern.startswith("*") and pattern.endswith("*"):
            # *text* pattern - contains
            search_text = pattern[1:-1]
            return search_text in filename
        elif pattern.startswith("*"):
            # *text pattern - ends with
            search_text = pattern[1:]
            return filename.endswith(search_text)
        elif pattern.endswith("*"):
            # text* pattern - starts with
            search_text = pattern[:-1]
            return filename.startswith(search_text)
        else:
            # exact match
            return filename == pattern
    
    def read_file(self, device: str, filename: str) -> str:
        """Read a file from the robot's FTP server.
        
        Args:
            device: Device to read from (e.g., "MD:", "UD1:").
            filename: Name of the file to read.
            
        Returns:
            The file contents as a string.
            
        Raises:
            RobotFTPError: If reading fails.
        """
        self._ensure_connected()
        
        # Make sure device has a colon at the end
        if not device.endswith(':'):
            device = f"{device}:"
        
        # Build the full path
        filepath = f"{device}/{filename}"
        
        try:
            # Retrieve the file content
            content = []
            self.ftp.retrlines(f"RETR {filepath}", content.append)
            
            # Join lines and return as a single string
            file_content = "\n".join(content)
            logger.info(f"Read file {filepath}, {len(file_content)} bytes")
            return file_content
            
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to read file {filepath}: {e}")
            raise RobotFTPError(f"Failed to read file {filepath}: {e}")

    def __enter__(self):
        """Context manager entry method."""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit method."""
        self.disconnect()
        
    def get_pwd(self) -> str:
        """Get the current working directory on the FTP server.
        
        Returns:
            The current working directory path.
            
        Raises:
            RobotFTPError: If getting the PWD fails.
        """
        self._ensure_connected()
        
        try:
            pwd = self.ftp.pwd()
            logger.info(f"Current working directory: {pwd}")
            return pwd
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to get current directory: {e}")
            raise RobotFTPError(f"Failed to get current directory: {e}")
    
    def create_directory(self, path: str) -> bool:
        """Create a new directory on the FTP server.
        
        Args:
            path: Path of the directory to create.
            
        Returns:
            True if directory was created successfully, False otherwise.
            
        Raises:
            RobotFTPError: If directory creation fails.
        """
        self._ensure_connected()
        
        try:
            self.ftp.mkd(path)
            logger.info(f"Created directory: {path}")
            return True
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to create directory {path}: {e}")
            raise RobotFTPError(f"Failed to create directory {path}: {e}")
    
    def remove_directory(self, path: str) -> bool:
        """Remove a directory on the FTP server.
        
        Args:
            path: Path of the directory to remove.
            
        Returns:
            True if directory was removed successfully, False otherwise.
            
        Raises:
            RobotFTPError: If directory removal fails.
        """
        self._ensure_connected()
        
        try:
            self.ftp.rmd(path)
            logger.info(f"Removed directory: {path}")
            return True
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to remove directory {path}: {e}")
            raise RobotFTPError(f"Failed to remove directory {path}: {e}")
    
    def remove_file(self, filepath: str) -> bool:
        """Remove a file on the FTP server.
        
        Args:
            filepath: Path of the file to remove.
            
        Returns:
            True if file was removed successfully, False otherwise.
            
        Raises:
            RobotFTPError: If file removal fails.
        """
        self._ensure_connected()
        
        try:
            self.ftp.delete(filepath)
            logger.info(f"Removed file: {filepath}")
            return True
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to remove file {filepath}: {e}")
            raise RobotFTPError(f"Failed to remove file {filepath}: {e}")
    
    def rename_file(self, old_path: str, new_path: str) -> bool:
        """Rename a file or directory on the FTP server.
        
        Args:
            old_path: Current path of the file or directory.
            new_path: New path for the file or directory.
            
        Returns:
            True if rename was successful, False otherwise.
            
        Raises:
            RobotFTPError: If rename fails.
        """
        self._ensure_connected()
        
        try:
            self.ftp.rename(old_path, new_path)
            logger.info(f"Renamed {old_path} to {new_path}")
            return True
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to rename {old_path} to {new_path}: {e}")
            raise RobotFTPError(f"Failed to rename {old_path} to {new_path}: {e}")
    
    def write_file(self, device: str, filename: str, content: Union[str, bytes, BinaryIO]) -> bool:
        """Write content to a file on the robot's FTP server.
        
        Args:
            device: Device to write to (e.g., "MD:", "UD1:").
            filename: Name of the file to write.
            content: Content to write to the file. Can be a string, bytes, or file-like object.
            
        Returns:
            True if file was written successfully, False otherwise.
            
        Raises:
            RobotFTPError: If writing fails.
        """
        self._ensure_connected()
        
        # Make sure device has a colon at the end
        if not device.endswith(':'):
            device = f"{device}:"
        
        # Build the full path
        filepath = f"{device}/{filename}"
        
        try:
            # Handle different content types
            if isinstance(content, str):
                # String content - convert to BytesIO
                buffer = BytesIO(content.encode('utf-8'))
                self.ftp.storbinary(f"STOR {filepath}", buffer)
            elif isinstance(content, bytes):
                # Bytes content - convert to BytesIO
                buffer = BytesIO(content)
                self.ftp.storbinary(f"STOR {filepath}", buffer)
            else:
                # Assume it's a file-like object
                self.ftp.storbinary(f"STOR {filepath}", content)
            
            logger.info(f"Wrote file {filepath}")
            return True
            
        except (error_perm, error_temp, TypeError) as e:
            logger.error(f"Failed to write file {filepath}: {e}")
            raise RobotFTPError(f"Failed to write file {filepath}: {e}")
    
    def write_text_file(self, device: str, filename: str, content: str) -> bool:
        """Write text content to a file on the robot's FTP server using ASCII/TEXT mode.
        
        This is useful for creating text-based program files that need proper line endings.
        
        Args:
            device: Device to write to (e.g., "MD:", "UD1:").
            filename: Name of the file to write.
            content: Text content to write to the file.
            
        Returns:
            True if file was written successfully, False otherwise.
            
        Raises:
            RobotFTPError: If writing fails.
        """
        self._ensure_connected()
        
        # Make sure device has a colon at the end
        if not device.endswith(':'):
            device = f"{device}:"
        
        # Build the full path
        filepath = f"{device}/{filename}"
        
        try:
            # Convert the string content to a StringIO object
            content_io = StringIO(content)
            
            # Use STOR command with ASCII/TEXT mode
            self.ftp.storlines(f"STOR {filepath}", content_io)
            
            logger.info(f"Wrote text file {filepath}")
            return True
            
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to write text file {filepath}: {e}")
            raise RobotFTPError(f"Failed to write text file {filepath}: {e}")
    
    def change_directory(self, path: str) -> bool:
        """Change the current working directory on the FTP server.
        
        Args:
            path: Path to change to.
            
        Returns:
            True if directory change was successful, False otherwise.
            
        Raises:
            RobotFTPError: If directory change fails.
        """
        self._ensure_connected()
        
        try:
            self.ftp.cwd(path)
            logger.info(f"Changed directory to: {path}")
            return True
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to change directory to {path}: {e}")
            raise RobotFTPError(f"Failed to change directory to {path}: {e}")
    
    def get_file_size(self, filepath: str) -> int:
        """Get the size of a file on the FTP server.
        
        Args:
            filepath: Path of the file.
            
        Returns:
            Size of the file in bytes.
            
        Raises:
            RobotFTPError: If getting file size fails.
        """
        self._ensure_connected()
        
        try:
            size = self.ftp.size(filepath)
            if size is None:
                logger.warning(f"Could not determine size of {filepath}")
                return -1
            logger.info(f"Size of {filepath}: {size} bytes")
            return size
        except (error_perm, error_temp) as e:
            logger.error(f"Failed to get size of file {filepath}: {e}")
            raise RobotFTPError(f"Failed to get size of file {filepath}: {e}")
    
    def download_binary_file(self, remote_path: str, local_path: str) -> bool:
        """Download a binary file from the FTP server to a local path.
        
        Args:
            remote_path: Path of the file on the FTP server.
            local_path: Local path to save the file to.
            
        Returns:
            True if download was successful, False otherwise.
            
        Raises:
            RobotFTPError: If download fails.
        """
        self._ensure_connected()
        
        try:
            with open(local_path, 'wb') as local_file:
                self.ftp.retrbinary(f"RETR {remote_path}", local_file.write)
            
            logger.info(f"Downloaded {remote_path} to {local_path}")
            return True
        except (error_perm, error_temp, IOError) as e:
            logger.error(f"Failed to download {remote_path} to {local_path}: {e}")
            raise RobotFTPError(f"Failed to download {remote_path}: {e}")