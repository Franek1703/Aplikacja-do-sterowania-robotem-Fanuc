"""
Command listener.

Listens for new commands in Firebase RTDB and dispatches them.
See firebase_protocol.md section 4 for command structure.
"""

import logging
import time
import threading
from typing import Optional, Dict, Any

from firebase_admin import db

try:
    from .models import Command, FTPCommand
    from .dispatcher import CommandDispatcher
except ImportError:
    from models import Command, FTPCommand
    from dispatcher import CommandDispatcher

logger = logging.getLogger(__name__)


class CommandListener:
    """Listens for commands in Firebase RTDB and executes them.
    
    Monitors:
    - /devices/{deviceId}/robots/{robotId}/commands
    - /devices/{deviceId}/robots/{robotId}/ftp/requests
    """
    
    def __init__(
        self,
        device_id: str,
        robot_id: str,
        dispatcher: CommandDispatcher,
        rtdb_root: db.Reference,
    ):
        """Initialize command listener.
        
        Args:
            device_id: Device (Raspberry Pi) identifier
            robot_id: Robot identifier
            dispatcher: Command dispatcher
            rtdb_root: Firebase RTDB root reference
        """
        self.device_id = device_id
        self.robot_id = robot_id
        self.dispatcher = dispatcher
        self.rtdb_root = rtdb_root
        
        self._running = False
        self._thread: Optional[threading.Thread] = None
        
        # RTDB references
        self.commands_ref = rtdb_root.child(
            f"devices/{device_id}/robots/{robot_id}/commands"
        )
        self.ftp_requests_ref = rtdb_root.child(
            f"devices/{device_id}/robots/{robot_id}/ftp/requests"
        )
        
        # Track processed commands to avoid duplicates
        self._processed_commands: set = set()
        
        logger.info(f"Initialized CommandListener for device={device_id}, robot={robot_id}")
    
    def start(self) -> None:
        """Start the command listener thread."""
        if self._running:
            logger.warning("CommandListener already running")
            return
        
        self._running = True
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()
        
        logger.info("CommandListener started")
    
    def stop(self) -> None:
        """Stop the command listener thread."""
        if not self._running:
            return
        
        self._running = False
        
        if self._thread:
            self._thread.join(timeout=5.0)
        
        logger.info("CommandListener stopped")
    
    def _run_loop(self) -> None:
        """Main loop for command listening.
        
        Uses polling approach for reliability on Raspberry Pi.
        """
        logger.info("CommandListener loop started")
        
        while self._running:
            try:
                # Check for robot commands
                self._check_robot_commands()
                
                # Check for FTP commands
                self._check_ftp_commands()
                
            except Exception as e:
                logger.error(f"Error in command listener loop: {e}", exc_info=True)
            
            # Poll every 0.5 seconds
            time.sleep(0.5)
        
        logger.info("CommandListener loop ended")
    
    def _check_robot_commands(self) -> None:
        """Check for pending robot commands."""
        try:
            commands_data = self.commands_ref.get()
            
            if not commands_data:
                return
            
            for command_id, command_data in commands_data.items():
                if not isinstance(command_data, dict):
                    continue
                
                # Skip if already processed
                if command_id in self._processed_commands:
                    continue
                
                # Only process pending commands
                if command_data.get("status") != "pending":
                    continue
                
                logger.info(f"Processing robot command: {command_id}")
                
                # Mark as processed
                self._processed_commands.add(command_id)
                
                # Parse command
                try:
                    command = Command.from_dict(command_data, command_id)
                except Exception as e:
                    logger.error(f"Failed to parse command {command_id}: {e}")
                    continue
                
                # Execute command in a separate thread to avoid blocking
                threading.Thread(
                    target=self._execute_robot_command,
                    args=(command_id, command),
                    daemon=True
                ).start()
                
        except Exception as e:
            logger.error(f"Error checking robot commands: {e}", exc_info=True)
    
    def _check_ftp_commands(self) -> None:
        """Check for pending FTP commands."""
        try:
            ftp_data = self.ftp_requests_ref.get()
            
            if not ftp_data:
                return
            
            for request_id, request_data in ftp_data.items():
                if not isinstance(request_data, dict):
                    continue
                
                # Skip if already processed
                ftp_key = f"ftp_{request_id}"
                if ftp_key in self._processed_commands:
                    continue
                
                # Only process pending requests
                if request_data.get("status") != "pending":
                    continue
                
                logger.info(f"Processing FTP request: {request_id}")
                
                # Mark as processed
                self._processed_commands.add(ftp_key)
                
                # Parse FTP command
                try:
                    ftp_command = FTPCommand.from_dict(request_data, request_id)
                except Exception as e:
                    logger.error(f"Failed to parse FTP request {request_id}: {e}")
                    continue
                
                # Execute FTP command in a separate thread
                threading.Thread(
                    target=self._execute_ftp_command,
                    args=(request_id, ftp_command),
                    daemon=True
                ).start()
                
        except Exception as e:
            logger.error(f"Error checking FTP commands: {e}", exc_info=True)
    
    def _execute_robot_command(self, command_id: str, command: Command) -> None:
        """Execute a robot command and update Firebase.
        
        Args:
            command_id: Command identifier
            command: Command object
        """
        command_ref = self.commands_ref.child(command_id)
        
        try:
            # Update status to running
            command_ref.child("status").set("running")
            logger.info(f"Executing command {command_id}: {command.type}")
            
            # Dispatch command
            result = self.dispatcher.dispatch(command)
            
            # Update result in Firebase
            command_ref.child("result").set(result.to_dict())
            
            # Update status based on result
            if result.code == 0:
                command_ref.child("status").set("success")
                logger.info(f"Command {command_id} completed successfully")
            else:
                command_ref.child("status").set("error")
                logger.warning(f"Command {command_id} failed: {result.message}")
                
        except Exception as e:
            logger.error(f"Error executing command {command_id}: {e}", exc_info=True)
            
            # Update Firebase with error
            try:
                command_ref.child("status").set("error")
                command_ref.child("result").set({
                    "code": 1,
                    "message": f"Exception: {str(e)}",
                    "completedAt": int(time.time())
                })
            except Exception as update_error:
                logger.error(f"Failed to update error status: {update_error}")
    
    def _execute_ftp_command(self, request_id: str, ftp_command: FTPCommand) -> None:
        """Execute an FTP command and update Firebase.
        
        Args:
            request_id: Request identifier
            ftp_command: FTP command object
        """
        request_ref = self.ftp_requests_ref.child(request_id)
        response_ref = self.rtdb_root.child(
            f"devices/{self.device_id}/robots/{self.robot_id}/ftp/responses/{request_id}"
        )
        
        try:
            # Update status to running
            request_ref.child("status").set("running")
            logger.info(f"Executing FTP request {request_id}: {ftp_command.type}")
            
            # Dispatch FTP command
            result = self.dispatcher.dispatch(ftp_command)
            
            # Write response
            response_data = {
                "requestId": request_id,
                "type": ftp_command.type,
                "status": "success" if result.code == 0 else "error",
                "result": result.to_dict(),
                "completedAt": result.completedAt
            }
            response_ref.set(response_data)
            
            # Update request status
            request_ref.child("result").set(result.to_dict())
            
            if result.code == 0:
                request_ref.child("status").set("success")
                logger.info(f"FTP request {request_id} completed successfully")
            else:
                request_ref.child("status").set("error")
                logger.warning(f"FTP request {request_id} failed: {result.message}")
                
        except Exception as e:
            logger.error(f"Error executing FTP request {request_id}: {e}", exc_info=True)
            
            # Update Firebase with error
            try:
                request_ref.child("status").set("error")
                error_result = {
                    "code": 1,
                    "message": f"Exception: {str(e)}",
                    "completedAt": int(time.time())
                }
                request_ref.child("result").set(error_result)
                response_ref.set({
                    "requestId": request_id,
                    "type": ftp_command.type,
                    "status": "error",
                    "result": error_result,
                    "completedAt": int(time.time())
                })
            except Exception as update_error:
                logger.error(f"Failed to update error status: {update_error}")

