"""
FTP client for Fanuc robots.

This module provides functionality to connect, list and read files from a Fanuc robot's FTP server.
It also supports file and directory operations like creating, removing, and renaming files and directories.
"""

from enum import Enum
from ftplib import FTP, error_perm, error_temp
import logging
import os
from typing import List, Optional, BinaryIO, Union, TYPE_CHECKING
from io import StringIO, BytesIO

if TYPE_CHECKING:
    from robot.alarm_parser import Alarm

# Setup logging
logger = logging.getLogger(__name__)


class AlarmLogType(Enum):
    """
    FANUC alarm log file types with their exact .LS filenames.
    Used only for selecting which error log file to read.
    Parsing will be implemented later.
    """
    ALL  = "ERRALL.LS"   # Combined log of all errors – DEFAULT
    SYS  = "ERRSYS.LS"   # System controller errors
    MOT  = "ERRMOT.LS"   # Servo/motion-related errors
    COMM = "ERRCOMM.LS"  # Communication errors (Ethernet, TCP/IP, etc.)
    APP  = "ERRAPP.LS"   # Application-related errors
    ACT  = "ERRACT.LS"   # Actual/current errors
    EXT  = "ERREXT.LS"   # Extended alarm log


class RobotFileInfo:
    """Data model for file information from FTP listing."""
    
    def __init__(self, name: str, size: int, modify_time: str, is_dir: bool, permissions: str):
        """Initialize the file info.
        
        Args:
            name: Name of the file
            size: Size in bytes
            modify_time: Modification time string
            is_dir: Whether this is a directory
            permissions: Permission string from FTP listing
        """
        self.name = name
        self.size = size
        self.modify_time = modify_time
        self.is_dir = is_dir
        self.permissions = permissions
    
    def __str__(self) -> str:
        """String representation of the file info."""
        type_str = "Directory" if self.is_dir else "File"
        return f"{type_str}: {self.name} ({self.size} bytes, modified: {self.modify_time})"
    
    def __repr__(self) -> str:
        """Detailed representation of the file info."""
        return f"RobotFileInfo(name='{self.name}', size={self.size}, modify_time='{self.modify_time}', is_dir={self.is_dir}, permissions='{self.permissions}')"


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
    
    def list_files(self, device: str = "MD:", pattern: str = "*", types: str = "ALL", change_dir: bool = True) -> List[RobotFileInfo]:
        """List files on the robot's FTP server.
        
        Args:
            device: Device to list files from (e.g., "MD:", "UD1:"), defaults to "MD:".
            pattern: File pattern to match, defaults to "*".
            types: Type of files to list ("TP", "KAREL", or "ALL"), defaults to "ALL".
            change_dir: Whether to change to the specified directory before listing.
            
        Returns:
            A list of RobotFileInfo objects containing file details.
            
        Raises:
            RobotFTPError: If listing fails.
        """
        self._ensure_connected()
        
        try:
            # Change to the requested device if needed
            if change_dir:
                self.ftp.cwd(device)
                logger.info(f"Successfully changed to directory: {device}")
            
            # Get the raw file listing using binary mode
            file_list = []
            try:
                # Use a binary buffer to collect the data
                buffer = BytesIO()
                self.ftp.retrbinary('LIST', buffer.write)
                buffer.seek(0)
                raw_data = buffer.getvalue()
                
                # Try different encodings to decode the entire listing
                decoded_data = None
                for encoding in ['cp1252', 'iso-8859-1', 'utf-8', 'shift-jis']:
                    try:
                        decoded_data = raw_data.decode(encoding)
                        logger.debug(f"Successfully decoded using {encoding}")
                        break
                    except UnicodeDecodeError:
                        continue
                
                if decoded_data is None:
                    # If all encodings fail, use replace mode
                    decoded_data = raw_data.decode('cp1252', errors='replace')
                    logger.warning("Using fallback encoding with 'replace' mode")
                
                # Split into lines and clean up
                file_list = [line.strip() for line in decoded_data.splitlines() if line.strip()]
                logger.debug(f"Successfully listed {len(file_list)} files")
                
            except Exception as e:
                logger.error(f"Error during directory listing: {e}")
                raise RobotFTPError(f"Failed to list directory: {e}")
            
            # Process the file listing
            result = []
            for line in file_list:
                try:
                    # Example line: "drw-rw-rw- 1 noone nogroup 512 oct 23 2025 test_dir"
                    parts = line.split(None, 8)  # Split into at most 9 parts
                    if len(parts) < 9:
                        continue
                    
                    permissions = parts[0]
                    size = int(parts[4])
                    # Combine month, day, year for modify time
                    modify_time = f"{parts[5]} {parts[6]} {parts[7]}"
                    name = parts[8].strip()
                    is_dir = permissions.startswith('d')
                    
                    # Create file info object
                    file_info = RobotFileInfo(
                        name=name,
                        size=size,
                        modify_time=modify_time,
                        is_dir=is_dir,
                        permissions=permissions
                    )
                    
                    # Check if it matches the requested pattern
                    if not self._match_pattern(name, pattern):
                        continue
                    
                    # Filter by file type if specified
                    if types != "ALL" and not is_dir:
                        ext = os.path.splitext(name)[1].upper()
                        if ext in self.EXTENSION_TO_TYPE and self.EXTENSION_TO_TYPE[ext] != types:
                            continue
                    
                    result.append(file_info)
                    
                except Exception as e:
                    logger.warning(f"Failed to parse line '{line}': {e}")
                    continue
            
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
        # if not device.endswith(':'):
        #     device = f"{device}:"
        
        # Build the full path
        filepath = fr"{device}\{filename}"
        
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
        
        # Build the full path
        filepath = fr"{device}\{filename}"
        
        try:
            # Convert the content to bytes and create a BytesIO object
            # Note: Fanuc robots typically expect ASCII or Latin-1 encoding
            content_bytes = content.encode('latin-1', errors='replace')
            buffer = BytesIO(content_bytes)
            
            # Use STOR command in binary mode
            self.ftp.storbinary(f"STOR {filepath}", buffer)
            
            logger.info(f"Wrote text file {filepath}")
            return True
            
        except (error_perm, error_temp, UnicodeError) as e:
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
    
    def read_alarm_logs(self, kind: AlarmLogType = AlarmLogType.ALL, device: str = "MD:") -> List["Alarm"]:
        """Read and parse alarm log files from the robot's FTP server.
        
        Args:
            kind: Type of alarm log to read (defaults to AlarmLogType.ALL for ERRALL.LS).
            device: Device to read from (e.g., "MD:", "UD1:"), defaults to "MD:".
            
        Returns:
            A list of parsed Alarm objects.
            
        Raises:
            RobotFTPError: If reading the alarm log fails.
        """
        self._ensure_connected()
        
        # Import here to avoid circular dependency
        from robot.alarm_parser import AlarmLogParser
        
        # Get the filename from the enum value
        filename = kind.value
        
        # Use the existing read_file method to read the alarm log
        logger.info(f"Reading alarm log: {filename} from {device}")
        log_content = self.read_file(device=device, filename=filename)
        
        # Parse and return the alarms
        alarms = AlarmLogParser.parse_log(log_content)
        logger.info(f"Parsed {len(alarms)} alarms from {filename}")
        return alarms
    
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