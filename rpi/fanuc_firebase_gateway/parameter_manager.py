"""
Parameter Manager for robot parameters.

Handles parameter definitions from Firestore and live values in RTDB.
"""

import logging
import time
from typing import Dict, Any, Optional, List
from datetime import datetime

try:
    from .models import ParameterDefinition, ParameterValue, ParameterUpdate
    from .firebase_client import get_firestore_client, get_rtdb_root
except ImportError:
    from models import ParameterDefinition, ParameterValue, ParameterUpdate
    from firebase_client import get_firestore_client, get_rtdb_root

logger = logging.getLogger(__name__)


class ParameterManager:
    """Manages robot parameters from Firestore and RTDB."""
    
    def __init__(self, device_id: str, robot_id: str):
        """Initialize parameter manager.
        
        Args:
            device_id: Device identifier
            robot_id: Robot identifier
        """
        self.device_id = device_id
        self.robot_id = robot_id
        self.firestore_client = get_firestore_client()
        self.rtdb_root = get_rtdb_root()
        
        # Cache for parameter definitions
        self._definitions: Dict[str, ParameterDefinition] = {}
        
        logger.info(f"Initialized ParameterManager for robot {robot_id}")
    
    def load_definitions(self) -> Dict[str, ParameterDefinition]:
        """Load parameter definitions from Firestore.
        
        Returns:
            Dictionary of parameter definitions keyed by parameter ID
        """
        try:
            params_ref = self.firestore_client.collection('robots').document(
                self.robot_id
            ).collection('parameters')
            
            params_docs = params_ref.stream()
            
            definitions = {}
            for doc in params_docs:
                data = doc.to_dict()
                if data:
                    param_def = ParameterDefinition(
                        id=data.get('id', doc.id),
                        name=data['name'],
                        defaultValue=data['defaultValue'],
                        type=data['type'],
                        category=data['category'],
                        isLocked=data.get('isLocked', False),
                        description=data.get('description', ''),
                        unit=data.get('unit'),
                        minValue=data.get('minValue'),
                        maxValue=data.get('maxValue')
                    )
                    definitions[param_def.id] = param_def
            
            self._definitions = definitions
            logger.info(f"Loaded {len(definitions)} parameter definitions for robot {self.robot_id}")
            return definitions
            
        except Exception as e:
            logger.error(f"Failed to load parameter definitions: {e}", exc_info=True)
            return {}
    
    def initialize_rtdb_parameters(self) -> None:
        """Initialize RTDB parameters with default values if not present."""
        try:
            if not self._definitions:
                self.load_definitions()
            
            rtdb_params_ref = self.rtdb_root.child(
                f"devices/{self.device_id}/robots/{self.robot_id}/parameters"
            )
            
            # Check if parameters already exist
            existing_params = rtdb_params_ref.get()
            
            if existing_params is None:
                # Initialize with default values
                initial_params = {}
                for param_id, param_def in self._definitions.items():
                    initial_params[param_id] = {
                        "value": param_def.defaultValue,
                        "updatedAt": int(time.time() * 1000),
                        "updatedBy": "system"
                    }
                
                rtdb_params_ref.set(initial_params)
                logger.info(f"Initialized {len(initial_params)} parameters in RTDB for robot {self.robot_id}")
            else:
                # Check for missing parameters and add them
                updates = {}
                for param_id, param_def in self._definitions.items():
                    if param_id not in existing_params:
                        updates[param_id] = {
                            "value": param_def.defaultValue,
                            "updatedAt": int(time.time() * 1000),
                            "updatedBy": "system"
                        }
                
                if updates:
                    rtdb_params_ref.update(updates)
                    logger.info(f"Added {len(updates)} missing parameters to RTDB for robot {self.robot_id}")
                else:
                    logger.info(f"All parameters already initialized in RTDB for robot {self.robot_id}")
                    
        except Exception as e:
            logger.error(f"Failed to initialize RTDB parameters: {e}", exc_info=True)
    
    def get_parameter(self, parameter_id: str) -> Optional[ParameterValue]:
        """Get current parameter value from RTDB.
        
        Args:
            parameter_id: Parameter identifier
            
        Returns:
            ParameterValue or None if not found
        """
        try:
            param_ref = self.rtdb_root.child(
                f"devices/{self.device_id}/robots/{self.robot_id}/parameters/{parameter_id}"
            )
            
            param_data = param_ref.get()
            
            if param_data:
                return ParameterValue(
                    value=param_data.get('value'),
                    updatedAt=param_data.get('updatedAt', int(time.time() * 1000)),
                    updatedBy=param_data.get('updatedBy', 'unknown')
                )
            
            return None
            
        except Exception as e:
            logger.error(f"Failed to get parameter {parameter_id}: {e}")
            return None
    
    def get_all_parameters(self) -> Dict[str, ParameterValue]:
        """Get all parameter values from RTDB.
        
        Returns:
            Dictionary of parameter values keyed by parameter ID
        """
        try:
            params_ref = self.rtdb_root.child(
                f"devices/{self.device_id}/robots/{self.robot_id}/parameters"
            )
            
            params_data = params_ref.get()
            
            if not params_data:
                return {}
            
            parameters = {}
            for param_id, param_data in params_data.items():
                parameters[param_id] = ParameterValue(
                    value=param_data.get('value'),
                    updatedAt=param_data.get('updatedAt', int(time.time() * 1000)),
                    updatedBy=param_data.get('updatedBy', 'unknown')
                )
            
            return parameters
            
        except Exception as e:
            logger.error(f"Failed to get all parameters: {e}", exc_info=True)
            return {}
    
    def update_parameter(self, parameter_id: str, value: Any, updated_by: str = "system") -> bool:
        """Update parameter value in RTDB.
        
        Args:
            parameter_id: Parameter identifier
            value: New parameter value
            updated_by: User ID who updated the parameter
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Check if parameter is locked
            if parameter_id in self._definitions:
                param_def = self._definitions[parameter_id]
                if param_def.isLocked:
                    logger.warning(f"Cannot update locked parameter {parameter_id}")
                    return False
                
                # Validate type
                if param_def.type == "number" and not isinstance(value, (int, float)):
                    logger.error(f"Invalid type for parameter {parameter_id}: expected number, got {type(value)}")
                    return False
                elif param_def.type == "boolean" and not isinstance(value, bool):
                    logger.error(f"Invalid type for parameter {parameter_id}: expected boolean, got {type(value)}")
                    return False
                elif param_def.type == "string" and not isinstance(value, str):
                    logger.error(f"Invalid type for parameter {parameter_id}: expected string, got {type(value)}")
                    return False
                
                # Validate range for numbers
                if param_def.type == "number":
                    if param_def.minValue is not None and value < param_def.minValue:
                        logger.error(f"Value {value} below minimum {param_def.minValue} for parameter {parameter_id}")
                        return False
                    if param_def.maxValue is not None and value > param_def.maxValue:
                        logger.error(f"Value {value} above maximum {param_def.maxValue} for parameter {parameter_id}")
                        return False
            
            # Update in RTDB
            param_ref = self.rtdb_root.child(
                f"devices/{self.device_id}/robots/{self.robot_id}/parameters/{parameter_id}"
            )
            
            param_ref.set({
                "value": value,
                "updatedAt": int(time.time() * 1000),
                "updatedBy": updated_by
            })
            
            logger.info(f"Updated parameter {parameter_id} to {value} by {updated_by}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to update parameter {parameter_id}: {e}", exc_info=True)
            return False
    
    def validate_parameter(self, parameter_id: str, value: Any) -> tuple[bool, str]:
        """Validate parameter value against definition.
        
        Args:
            parameter_id: Parameter identifier
            value: Value to validate
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        if parameter_id not in self._definitions:
            return False, f"Parameter {parameter_id} not found"
        
        param_def = self._definitions[parameter_id]
        
        # Check if locked
        if param_def.isLocked:
            return False, f"Parameter {parameter_id} is locked"
        
        # Check type
        if param_def.type == "number":
            if not isinstance(value, (int, float)):
                return False, f"Expected number, got {type(value).__name__}"
            if param_def.minValue is not None and value < param_def.minValue:
                return False, f"Value must be >= {param_def.minValue}"
            if param_def.maxValue is not None and value > param_def.maxValue:
                return False, f"Value must be <= {param_def.maxValue}"
        elif param_def.type == "boolean":
            if not isinstance(value, bool):
                return False, f"Expected boolean, got {type(value).__name__}"
        elif param_def.type == "string":
            if not isinstance(value, str):
                return False, f"Expected string, got {type(value).__name__}"
        
        return True, ""

