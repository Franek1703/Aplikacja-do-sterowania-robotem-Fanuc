"""
Command dispatcher.

Routes commands from Firebase to appropriate robot/FTP handlers.
See firebase_protocol.md for complete command specifications.
"""

import logging
import time
from typing import Union

try:
    from .models import Command, FTPCommand, CommandResult
    from .robot_adapter import RobotInterface
    from .ftp_bridge import FTPBridge
    from .parameter_manager import ParameterManager
except ImportError:
    from models import Command, FTPCommand, CommandResult
    from robot_adapter import RobotInterface
    from ftp_bridge import FTPBridge
    from parameter_manager import ParameterManager

logger = logging.getLogger(__name__)


class CommandDispatcher:
    """Dispatches commands to robot or FTP handlers.
    
    Maps command types to handler methods as defined in firebase_protocol.md.
    """
    
    def __init__(self, robot: RobotInterface, ftp_bridge: FTPBridge, parameter_manager: ParameterManager):
        """Initialize command dispatcher.
        
        Args:
            robot: Robot interface implementation
            ftp_bridge: FTP bridge for file operations
            parameter_manager: Parameter manager for robot parameters
        """
        self.robot = robot
        self.ftp_bridge = ftp_bridge
        self.parameter_manager = parameter_manager
        
        # Map command types to handler methods
        self.command_handlers = {
            # Motion commands (section 5.1)
            "move": self._handle_move,
            "jogStart": self._handle_jog_start,
            "jogStop": self._handle_jog_stop,
            "jogStopAll": self._handle_jog_stop_all,
            
            # Program execution (section 5.2)
            "runProgram": self._handle_run_program,
            "abortProgram": self._handle_abort_program,
            "selectProgram": self._handle_select_program,
            
            # Gripper control (section 5.3)
            "setGripper": self._handle_set_gripper,
            
            # Robot I/O (section 5.4)
            "setRDO": self._handle_set_rdo,
            "getRDO": self._handle_get_rdo,
            "setDOUT": self._handle_set_dout,
            "getDOUT": self._handle_get_dout,
            
            # System variables (section 5.5)
            "getSystemVar": self._handle_get_system_var,
            "setSystemVar": self._handle_set_system_var,
            
            # Robot configuration (section 5.6)
            "setTool": self._handle_set_tool,
            "setUserFrame": self._handle_set_user_frame,
            "setCoord": self._handle_set_coord,
            
            # Diagnostics (section 5.7)
            "getPowerConsumption": self._handle_get_power_consumption,
            "getRobotInfo": self._handle_get_robot_info,
            
            # Parameters (section 5.8)
            "updateParameter": self._handle_update_parameter,
            "getParameter": self._handle_get_parameter,
            "getAllParameters": self._handle_get_all_parameters,
        }
        
        logger.info(f"Initialized CommandDispatcher with {len(self.command_handlers)} handlers")
    
    def dispatch(self, command: Union[Command, FTPCommand]) -> CommandResult:
        """Dispatch a command to the appropriate handler.
        
        Args:
            command: Command or FTPCommand to execute
            
        Returns:
            CommandResult with execution result
        """
        # Handle FTP commands separately
        if isinstance(command, FTPCommand):
            logger.info(f"Dispatching FTP command: {command.type}")
            return self.ftp_bridge.handle_command(command)
        
        # Handle robot commands
        handler = self.command_handlers.get(command.type)
        
        if not handler:
            logger.error(f"Unknown command type: {command.type}")
            return CommandResult(
                code=1,
                message=f"Unknown command type: {command.type}",
                completedAt=int(time.time())
            )
        
        try:
            logger.info(f"Dispatching command: {command.type}")
            return handler(command.payload)
        except Exception as e:
            logger.error(f"Error executing command {command.type}: {e}", exc_info=True)
            return CommandResult(
                code=1,
                message=f"Error: {str(e)}",
                completedAt=int(time.time())
            )
    
    # Motion command handlers
    
    def _handle_move(self, payload: dict) -> CommandResult:
        """Handle move command (section 5.1)."""
        mode = payload.get("mode", "pose")
        vals = payload["vals"]
        velocity = payload.get("velocity", 20)
        acceleration = payload.get("acceleration", 100)
        cnt = payload.get("cnt", 0)
        linear = payload.get("linear", True)
        
        code, msg = self.robot.move(
            move_type=mode,
            vals=vals,
            velocity=velocity,
            acceleration=acceleration,
            cnt_val=cnt,
            linear=linear
        )
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    def _handle_jog_start(self, payload: dict) -> CommandResult:
        """Handle jogStart command (section 5.1)."""
        axis = payload["axis"]
        direction = payload["direction"]
        speed = payload.get("speed")
        step = payload.get("step")
        
        code, msg = self.robot.jog_start(
            axis=axis,
            direction=direction,
            speed=speed,
            step=step
        )
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    def _handle_jog_stop(self, payload: dict) -> CommandResult:
        """Handle jogStop command (section 5.1)."""
        axis = payload["axis"]
        
        code, msg = self.robot.jog_stop(axis=axis)
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    def _handle_jog_stop_all(self, payload: dict) -> CommandResult:
        """Handle jogStopAll command (section 5.1)."""
        code, msg = self.robot.jog_stop_all()
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    # Program execution handlers
    
    def _handle_run_program(self, payload: dict) -> CommandResult:
        """Handle runProgram command (section 5.2)."""
        prog_name = payload["name"]
        
        code, msg = self.robot.call_prog(prog_name)
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    def _handle_abort_program(self, payload: dict) -> CommandResult:
        """Handle abortProgram command (section 5.2)."""
        # Note: This would need to be implemented in robot.py
        # For now, return a placeholder
        logger.warning("abortProgram not yet implemented in robot interface")
        return CommandResult(
            code=1,
            message="abortProgram not yet implemented",
            completedAt=int(time.time())
        )
    
    def _handle_select_program(self, payload: dict) -> CommandResult:
        """Handle selectProgram command (section 5.2)."""
        # Note: This would need to be implemented in robot.py
        # For now, return a placeholder
        logger.warning("selectProgram not yet implemented in robot interface")
        return CommandResult(
            code=1,
            message="selectProgram not yet implemented",
            completedAt=int(time.time())
        )
    
    # Gripper control handler
    
    def _handle_set_gripper(self, payload: dict) -> CommandResult:
        """Handle setGripper command (section 5.3)."""
        state = payload["state"]
        
        # Map state to boolean
        if state == "open":
            value = True
        elif state == "close":
            value = False
        elif state == "toggle":
            # Would need to track current state
            logger.warning("toggle not fully implemented, defaulting to open")
            value = True
        else:
            return CommandResult(
                code=1,
                message=f"Invalid gripper state: {state}",
                completedAt=int(time.time())
            )
        
        code, msg = self.robot.gripper(value)
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    # I/O handlers
    
    def _handle_set_rdo(self, payload: dict) -> CommandResult:
        """Handle setRDO command (section 5.4)."""
        index = payload["index"]
        value = payload["value"]
        
        code, msg = self.robot.set_rdo(index, value)
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    def _handle_get_rdo(self, payload: dict) -> CommandResult:
        """Handle getRDO command (section 5.4)."""
        index = payload["index"]
        
        value = self.robot.get_rdo(index)
        
        return CommandResult(
            code=0,
            message=f"RDO[{index}] = {value}",
            completedAt=int(time.time()),
            data={"value": value}
        )
    
    def _handle_set_dout(self, payload: dict) -> CommandResult:
        """Handle setDOUT command (section 5.4)."""
        index = payload["index"]
        value = payload["value"]
        
        code, msg = self.robot.set_dout(index, value)
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    def _handle_get_dout(self, payload: dict) -> CommandResult:
        """Handle getDOUT command (section 5.4)."""
        index = payload["index"]
        
        value = self.robot.get_dout(index)
        
        return CommandResult(
            code=0,
            message=f"DOUT[{index}] = {value}",
            completedAt=int(time.time()),
            data={"value": value}
        )
    
    # System variable handlers
    
    def _handle_get_system_var(self, payload: dict) -> CommandResult:
        """Handle getSystemVar command (section 5.5)."""
        # Note: This would need to be implemented in robot.py
        var_name = payload["name"]
        logger.warning(f"getSystemVar not yet implemented for {var_name}")
        return CommandResult(
            code=1,
            message="getSystemVar not yet implemented",
            completedAt=int(time.time())
        )
    
    def _handle_set_system_var(self, payload: dict) -> CommandResult:
        """Handle setSystemVar command (section 5.5)."""
        var_name = payload["name"]
        value = payload["value"]
        
        # Assuming value is boolean for now
        if isinstance(value, bool):
            code, msg = self.robot.set_sys_var(var_name, value)
            return CommandResult(
                code=code,
                message=msg,
                completedAt=int(time.time())
            )
        else:
            logger.warning(f"setSystemVar with non-boolean value not yet supported")
            return CommandResult(
                code=1,
                message="Only boolean system variables supported currently",
                completedAt=int(time.time())
            )
    
    # Configuration handlers
    
    def _handle_set_tool(self, payload: dict) -> CommandResult:
        """Handle setTool command (section 5.6)."""
        tool_num = payload["toolNumber"]
        
        code, msg = self.robot.set_tool(tool_num)
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    def _handle_set_user_frame(self, payload: dict) -> CommandResult:
        """Handle setUserFrame command (section 5.6)."""
        user_frame = payload["userFrame"]
        
        code, msg = self.robot.set_user(user_frame)
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    def _handle_set_coord(self, payload: dict) -> CommandResult:
        """Handle setCoord command (section 5.6)."""
        coord_system = payload["coordSystem"]
        
        code, msg = self.robot.set_coord(coord_system)
        
        return CommandResult(
            code=code,
            message=msg,
            completedAt=int(time.time())
        )
    
    # Diagnostics handlers
    
    def _handle_get_power_consumption(self, payload: dict) -> CommandResult:
        """Handle getPowerConsumption command (section 5.7)."""
        power = self.robot.get_power_consumption()
        
        # Simulate voltage and current (would need real implementation)
        voltage = 220.0
        current = power / voltage if voltage > 0 else 0
        
        return CommandResult(
            code=0,
            message="Power consumption retrieved",
            completedAt=int(time.time()),
            data={
                "voltage": voltage,
                "current": current,
                "power": power
            }
        )
    
    def _handle_get_robot_info(self, payload: dict) -> CommandResult:
        """Handle getRobotInfo command (section 5.7)."""
        # Note: This would need to be implemented in robot.py
        logger.warning("getRobotInfo not yet implemented")
        return CommandResult(
            code=1,
            message="getRobotInfo not yet implemented",
            completedAt=int(time.time())
        )
    
    def _handle_update_parameter(self, payload: dict) -> CommandResult:
        """Handle updateParameter command (section 5.8)."""
        try:
            parameter_id = payload["parameterId"]
            value = payload["value"]
            updated_by = payload.get("updatedBy", "system")
            
            logger.info(f"Updating parameter {parameter_id} to {value}")
            
            # Validate parameter
            is_valid, error_msg = self.parameter_manager.validate_parameter(parameter_id, value)
            if not is_valid:
                return CommandResult(
                    code=1,
                    message=f"Parameter validation failed: {error_msg}",
                    completedAt=int(time.time())
                )
            
            # Update parameter
            success = self.parameter_manager.update_parameter(parameter_id, value, updated_by)
            
            if success:
                return CommandResult(
                    code=0,
                    message=f"Parameter {parameter_id} updated successfully",
                    completedAt=int(time.time()),
                    data={"parameterId": parameter_id, "value": value}
                )
            else:
                return CommandResult(
                    code=1,
                    message=f"Failed to update parameter {parameter_id}",
                    completedAt=int(time.time())
                )
                
        except KeyError as e:
            return CommandResult(
                code=1,
                message=f"Missing required field: {e}",
                completedAt=int(time.time())
            )
        except Exception as e:
            logger.error(f"Error updating parameter: {e}", exc_info=True)
            return CommandResult(
                code=1,
                message=f"Error updating parameter: {str(e)}",
                completedAt=int(time.time())
            )
    
    def _handle_get_parameter(self, payload: dict) -> CommandResult:
        """Handle getParameter command (section 5.8)."""
        try:
            parameter_id = payload["parameterId"]
            
            logger.info(f"Getting parameter {parameter_id}")
            
            param_value = self.parameter_manager.get_parameter(parameter_id)
            
            if param_value:
                return CommandResult(
                    code=0,
                    message=f"Parameter {parameter_id} retrieved",
                    completedAt=int(time.time()),
                    data={
                        "parameterId": parameter_id,
                        "value": param_value.value,
                        "updatedAt": param_value.updatedAt,
                        "updatedBy": param_value.updatedBy
                    }
                )
            else:
                return CommandResult(
                    code=1,
                    message=f"Parameter {parameter_id} not found",
                    completedAt=int(time.time())
                )
                
        except KeyError as e:
            return CommandResult(
                code=1,
                message=f"Missing required field: {e}",
                completedAt=int(time.time())
            )
        except Exception as e:
            logger.error(f"Error getting parameter: {e}", exc_info=True)
            return CommandResult(
                code=1,
                message=f"Error getting parameter: {str(e)}",
                completedAt=int(time.time())
            )
    
    def _handle_get_all_parameters(self, payload: dict) -> CommandResult:
        """Handle getAllParameters command (section 5.8)."""
        try:
            logger.info("Getting all parameters")
            
            all_params = self.parameter_manager.get_all_parameters()
            
            # Convert to dict format for Firebase
            params_data = {}
            for param_id, param_value in all_params.items():
                params_data[param_id] = {
                    "value": param_value.value,
                    "updatedAt": param_value.updatedAt,
                    "updatedBy": param_value.updatedBy
                }
            
            return CommandResult(
                code=0,
                message=f"Retrieved {len(all_params)} parameters",
                completedAt=int(time.time()),
                data={"parameters": params_data}
            )
                
        except Exception as e:
            logger.error(f"Error getting all parameters: {e}", exc_info=True)
            return CommandResult(
                code=1,
                message=f"Error getting all parameters: {str(e)}",
                completedAt=int(time.time())
            )

