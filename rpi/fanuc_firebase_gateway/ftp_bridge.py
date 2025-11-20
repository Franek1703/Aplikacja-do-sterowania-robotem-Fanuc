"""
FTP operations bridge.

Handles FTP commands as defined in firebase_protocol.md section 6.
"""

import logging
from typing import Tuple, Optional, List, Dict, Any
import sys
from pathlib import Path

try:
    from .models import FTPCommand, CommandResult, FileInfo
except ImportError:
    from models import FTPCommand, CommandResult, FileInfo

logger = logging.getLogger(__name__)


class FTPBridge:
    """Bridge for FTP operations to FANUC robot.
    
    Handles all FTP command types defined in firebase_protocol.md section 6.
    """
    
    def __init__(self, host: str, user: str = "anonymous", password: str = "", simulation: bool = False):
        """Initialize FTP bridge.
        
        Args:
            host: Robot IP address
            user: FTP username
            password: FTP password
            simulation: If True, use simulated FTP client
        """
        self.host = host
        self.user = user
        self.password = password
        self.simulation = simulation
        
        if not simulation:
            # Import real FTP client
            fanuc_package_path = Path(__file__).parent.parent / "fanuc_package" / "src"
            if str(fanuc_package_path) not in sys.path:
                sys.path.insert(0, str(fanuc_package_path))
            
            from robot.ftp import RobotFTP, RobotFTPError
            
            self.ftp = RobotFTP(host=host, user=user, password=password)
            self.FTPError = RobotFTPError
            logger.info(f"Initialized FTPBridge for {host}")
        else:
            self.ftp = SimulatedFTP()
            self.FTPError = Exception
            logger.info("Initialized FTPBridge in simulation mode")
    
    def handle_command(self, command: FTPCommand) -> CommandResult:
        """Handle an FTP command.
        
        Args:
            command: FTP command to execute
            
        Returns:
            CommandResult with execution result
        """
        handler_map = {
            "listFiles": self._handle_list_files,
            "readFile": self._handle_read_file,
            "writeFile": self._handle_write_file,
            "deleteFile": self._handle_delete_file,
            "renameFile": self._handle_rename_file,
            "createDirectory": self._handle_create_directory,
            "removeDirectory": self._handle_remove_directory,
        }
        
        handler = handler_map.get(command.type)
        if not handler:
            logger.error(f"Unknown FTP command type: {command.type}")
            return CommandResult(
                code=1,
                message=f"Unknown FTP command type: {command.type}",
                completedAt=int(time.time())
            )
        
        try:
            return handler(command.payload)
        except self.FTPError as e:
            logger.error(f"FTP error in {command.type}: {e}")
            return CommandResult(
                code=1,
                message=str(e),
                completedAt=int(time.time())
            )
        except Exception as e:
            logger.error(f"Unexpected error in {command.type}: {e}", exc_info=True)
            return CommandResult(
                code=1,
                message=f"Unexpected error: {str(e)}",
                completedAt=int(time.time())
            )
    
    def _handle_list_files(self, payload: Dict[str, Any]) -> CommandResult:
        """Handle listFiles command."""
        import time
        
        device = payload.get("device", "MD:")
        pattern = payload.get("pattern", "*")
        types = payload.get("types", "ALL")
        
        logger.info(f"Listing files: device={device}, pattern={pattern}, types={types}")
        
        try:
            self.ftp.connect()
            file_infos = self.ftp.list_files(device=device, pattern=pattern, types=types)
            
            # Convert to dict format
            files = []
            for file_info in file_infos:
                if hasattr(file_info, 'to_dict'):
                    files.append(file_info.to_dict())
                else:
                    # Handle RobotFileInfo from real FTP
                    files.append({
                        "name": file_info.name,
                        "size": file_info.size,
                        "modify_time": file_info.modify_time,
                        "is_dir": file_info.is_dir,
                        "permissions": file_info.permissions,
                    })
            
            return CommandResult(
                code=0,
                message=f"Listed {len(files)} files",
                completedAt=int(time.time()),
                data={"files": files}
            )
        finally:
            self.ftp.disconnect()
    
    def _handle_read_file(self, payload: Dict[str, Any]) -> CommandResult:
        """Handle readFile command."""
        import time
        
        device = payload.get("device", "MD:")
        filename = payload["filename"]
        
        logger.info(f"Reading file: device={device}, filename={filename}")
        
        try:
            self.ftp.connect()
            content = self.ftp.read_file(device=device, filename=filename)
            
            return CommandResult(
                code=0,
                message=f"Read file {filename}",
                completedAt=int(time.time()),
                data={"content": content}
            )
        finally:
            self.ftp.disconnect()
    
    def _handle_write_file(self, payload: Dict[str, Any]) -> CommandResult:
        """Handle writeFile command."""
        import time
        
        device = payload.get("device", "MD:")
        filename = payload["filename"]
        content = payload["content"]
        
        logger.info(f"Writing file: device={device}, filename={filename}")
        
        try:
            self.ftp.connect()
            self.ftp.write_text_file(device=device, filename=filename, content=content)
            
            return CommandResult(
                code=0,
                message=f"Wrote file {filename}",
                completedAt=int(time.time())
            )
        finally:
            self.ftp.disconnect()
    
    def _handle_delete_file(self, payload: Dict[str, Any]) -> CommandResult:
        """Handle deleteFile command."""
        import time
        
        device = payload.get("device", "MD:")
        filename = payload["filename"]
        
        logger.info(f"Deleting file: device={device}, filename={filename}")
        
        filepath = f"{device}\\{filename}"
        
        try:
            self.ftp.connect()
            self.ftp.remove_file(filepath)
            
            return CommandResult(
                code=0,
                message=f"Deleted file {filename}",
                completedAt=int(time.time())
            )
        finally:
            self.ftp.disconnect()
    
    def _handle_rename_file(self, payload: Dict[str, Any]) -> CommandResult:
        """Handle renameFile command."""
        import time
        
        old_name = payload["oldName"]
        new_name = payload["newName"]
        
        logger.info(f"Renaming file: {old_name} -> {new_name}")
        
        try:
            self.ftp.connect()
            self.ftp.rename_file(old_name, new_name)
            
            return CommandResult(
                code=0,
                message=f"Renamed {old_name} to {new_name}",
                completedAt=int(time.time())
            )
        finally:
            self.ftp.disconnect()
    
    def _handle_create_directory(self, payload: Dict[str, Any]) -> CommandResult:
        """Handle createDirectory command."""
        import time
        
        name = payload["name"]
        
        logger.info(f"Creating directory: {name}")
        
        try:
            self.ftp.connect()
            self.ftp.create_directory(name)
            
            return CommandResult(
                code=0,
                message=f"Created directory {name}",
                completedAt=int(time.time())
            )
        finally:
            self.ftp.disconnect()
    
    def _handle_remove_directory(self, payload: Dict[str, Any]) -> CommandResult:
        """Handle removeDirectory command."""
        import time
        
        name = payload["name"]
        
        logger.info(f"Removing directory: {name}")
        
        try:
            self.ftp.connect()
            self.ftp.remove_directory(name)
            
            return CommandResult(
                code=0,
                message=f"Removed directory {name}",
                completedAt=int(time.time())
            )
        finally:
            self.ftp.disconnect()


class SimulatedFTP:
    """Simulated FTP client for testing."""
    
    def __init__(self):
        """Initialize simulated FTP."""
        self.files = {
            "MD:": [
                FileInfo("MAIN001.TP", 1024, "Jan 15 2025", False, "-rw-rw-rw-"),
                FileInfo("MAIN002.TP", 2048, "Jan 16 2025", False, "-rw-rw-rw-"),
                FileInfo("TEST.KL", 512, "Jan 10 2025", False, "-rw-rw-rw-"),
            ]
        }
        self.connected = False
        logger.info("Initialized SimulatedFTP")
    
    def connect(self) -> bool:
        """Simulate connection."""
        logger.debug("SimulatedFTP: Connecting...")
        self.connected = True
        return True
    
    def disconnect(self) -> None:
        """Simulate disconnection."""
        logger.debug("SimulatedFTP: Disconnecting...")
        self.connected = False
    
    def list_files(self, device: str = "MD:", pattern: str = "*", types: str = "ALL") -> List[FileInfo]:
        """Simulate listing files."""
        logger.debug(f"SimulatedFTP: list_files(device={device}, pattern={pattern}, types={types})")
        return self.files.get(device, [])
    
    def read_file(self, device: str, filename: str) -> str:
        """Simulate reading a file."""
        logger.debug(f"SimulatedFTP: read_file(device={device}, filename={filename})")
        return f"# Simulated content of {filename}\n# This is a test file\n"
    
    def write_text_file(self, device: str, filename: str, content: str) -> bool:
        """Simulate writing a file."""
        logger.debug(f"SimulatedFTP: write_text_file(device={device}, filename={filename})")
        # Add to simulated file list
        if device not in self.files:
            self.files[device] = []
        self.files[device].append(
            FileInfo(filename, len(content), "Jan 20 2025", False, "-rw-rw-rw-")
        )
        return True
    
    def remove_file(self, filepath: str) -> bool:
        """Simulate removing a file."""
        logger.debug(f"SimulatedFTP: remove_file(filepath={filepath})")
        return True
    
    def rename_file(self, old_path: str, new_path: str) -> bool:
        """Simulate renaming a file."""
        logger.debug(f"SimulatedFTP: rename_file({old_path} -> {new_path})")
        return True
    
    def create_directory(self, path: str) -> bool:
        """Simulate creating a directory."""
        logger.debug(f"SimulatedFTP: create_directory(path={path})")
        return True
    
    def remove_directory(self, path: str) -> bool:
        """Simulate removing a directory."""
        logger.debug(f"SimulatedFTP: remove_directory(path={path})")
        return True

