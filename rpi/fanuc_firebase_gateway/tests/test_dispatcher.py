"""Tests for command dispatcher."""

import pytest
from fanuc_firebase_gateway.dispatcher import CommandDispatcher
from fanuc_firebase_gateway.robot_adapter import SimulatedRobotAdapter
from fanuc_firebase_gateway.ftp_bridge import FTPBridge
from fanuc_firebase_gateway.models import Command, CommandResult


@pytest.fixture
def robot():
    """Create a simulated robot for testing."""
    robot = SimulatedRobotAdapter()
    robot.connect()
    return robot


@pytest.fixture
def ftp_bridge():
    """Create an FTP bridge in simulation mode."""
    return FTPBridge(host="127.0.0.1", simulation=True)


@pytest.fixture
def dispatcher(robot, ftp_bridge):
    """Create a command dispatcher."""
    return CommandDispatcher(robot=robot, ftp_bridge=ftp_bridge)


def test_dispatcher_move_command(dispatcher):
    """Test dispatching a move command."""
    command = Command(
        type="move",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={
            "mode": "pose",
            "vals": [100.0, 200.0, 300.0, 180.0, 0.0, 90.0],
            "velocity": 50,
            "acceleration": 100,
            "cnt": 0,
            "linear": True,
        }
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert result.message is not None
    assert result.completedAt is not None


def test_dispatcher_jog_start_command(dispatcher):
    """Test dispatching a jogStart command."""
    command = Command(
        type="jogStart",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={
            "axis": "X",
            "direction": "+",
            "speed": 25,
            "step": 0.5,
        }
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert "jog" in result.message.lower()


def test_dispatcher_jog_stop_command(dispatcher):
    """Test dispatching a jogStop command."""
    command = Command(
        type="jogStop",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={"axis": "X"}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0


def test_dispatcher_jog_stop_all_command(dispatcher):
    """Test dispatching a jogStopAll command."""
    command = Command(
        type="jogStopAll",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0


def test_dispatcher_run_program_command(dispatcher):
    """Test dispatching a runProgram command."""
    command = Command(
        type="runProgram",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={"name": "MAIN001"}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert "MAIN001" in result.message


def test_dispatcher_set_gripper_command(dispatcher):
    """Test dispatching a setGripper command."""
    command = Command(
        type="setGripper",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={"state": "open"}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert "gripper" in result.message.lower()


def test_dispatcher_set_rdo_command(dispatcher):
    """Test dispatching a setRDO command."""
    command = Command(
        type="setRDO",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={"index": 5, "value": True}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0


def test_dispatcher_get_rdo_command(dispatcher):
    """Test dispatching a getRDO command."""
    # First set an RDO
    dispatcher.robot.set_rdo(5, True)
    
    command = Command(
        type="getRDO",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={"index": 5}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert result.data is not None
    assert "value" in result.data


def test_dispatcher_set_tool_command(dispatcher):
    """Test dispatching a setTool command."""
    command = Command(
        type="setTool",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={"toolNumber": 2}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert dispatcher.robot.tool_num == 2


def test_dispatcher_set_user_frame_command(dispatcher):
    """Test dispatching a setUserFrame command."""
    command = Command(
        type="setUserFrame",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={"userFrame": 3}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert dispatcher.robot.user_frame == 3


def test_dispatcher_set_coord_command(dispatcher):
    """Test dispatching a setCoord command."""
    command = Command(
        type="setCoord",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={"coordSystem": "USER"}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert dispatcher.robot.coord_system == "USER"


def test_dispatcher_get_power_consumption_command(dispatcher):
    """Test dispatching a getPowerConsumption command."""
    command = Command(
        type="getPowerConsumption",
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 0
    assert result.data is not None
    assert "power" in result.data
    assert "voltage" in result.data
    assert "current" in result.data


def test_dispatcher_unknown_command(dispatcher):
    """Test dispatching an unknown command type."""
    command = Command(
        type="unknownCommand",  # type: ignore
        status="pending",
        createdAt=1234567890,
        createdBy="test_user",
        payload={}
    )
    
    result = dispatcher.dispatch(command)
    
    assert result.code == 1
    assert "unknown" in result.message.lower()

