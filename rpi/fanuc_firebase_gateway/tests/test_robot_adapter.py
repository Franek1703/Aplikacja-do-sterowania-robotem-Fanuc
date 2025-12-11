"""Tests for robot adapters."""

import pytest
from fanuc_firebase_gateway.robot_adapter import SimulatedRobotAdapter


@pytest.fixture
def robot():
    """Create a simulated robot for testing."""
    robot = SimulatedRobotAdapter()
    robot.connect()
    return robot


def test_simulated_robot_connect():
    """Test simulated robot connection."""
    robot = SimulatedRobotAdapter()
    code, msg = robot.connect()
    
    assert code == 0
    assert robot.connected is True
    assert "connect" in msg.lower()


def test_simulated_robot_disconnect():
    """Test simulated robot disconnection."""
    robot = SimulatedRobotAdapter()
    robot.connect()
    robot.disconnect()
    
    assert robot.connected is False


def test_simulated_robot_get_curpos(robot):
    """Test getting current position."""
    pos = robot.get_curpos()
    
    assert len(pos) == 6
    assert all(isinstance(v, float) for v in pos)


def test_simulated_robot_get_curjpos(robot):
    """Test getting current joint positions."""
    joints = robot.get_curjpos()
    
    assert len(joints) == 6
    assert all(isinstance(v, float) for v in joints)


def test_simulated_robot_move_pose(robot):
    """Test moving to a pose."""
    target = [100.0, 200.0, 300.0, 180.0, 0.0, 90.0]
    
    code, msg = robot.move(
        move_type="pose",
        vals=target,
        velocity=50,
        acceleration=100,
        cnt_val=0,
        linear=True
    )
    
    assert code == 0
    assert robot.position == target


def test_simulated_robot_move_joint(robot):
    """Test moving to joint positions."""
    target = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0]
    
    code, msg = robot.move(
        move_type="joint",
        vals=target,
        velocity=50,
        acceleration=100,
        cnt_val=0,
        linear=False
    )
    
    assert code == 0
    assert robot.joints == target


def test_simulated_robot_jog_start(robot):
    """Test starting jog."""
    initial_x = robot.position[0]
    
    code, msg = robot.jog_start(axis="X", direction="+", speed=25, step=1.0)
    
    assert code == 0
    assert robot.position[0] == initial_x + 1.0


def test_simulated_robot_jog_stop(robot):
    """Test stopping jog."""
    code, msg = robot.jog_stop(axis="X")
    
    assert code == 0


def test_simulated_robot_jog_stop_all(robot):
    """Test stopping all jog operations."""
    code, msg = robot.jog_stop_all()
    
    assert code == 0


def test_simulated_robot_call_prog(robot):
    """Test calling a program."""
    code, msg = robot.call_prog("MAIN001")
    
    assert code == 0
    assert robot.active_program == "MAIN001"


def test_simulated_robot_gripper(robot):
    """Test gripper control."""
    code, msg = robot.gripper(True)
    
    assert code == 0
    assert robot.gripper_open is True
    
    code, msg = robot.gripper(False)
    
    assert code == 0
    assert robot.gripper_open is False


def test_simulated_robot_rdo(robot):
    """Test RDO operations."""
    # Set RDO
    code, msg = robot.set_rdo(5, True)
    assert code == 0
    
    # Get RDO
    value = robot.get_rdo(5)
    assert value == 1
    
    # Set RDO to False
    code, msg = robot.set_rdo(5, False)
    assert code == 0
    
    value = robot.get_rdo(5)
    assert value == 0


def test_simulated_robot_dout(robot):
    """Test DOUT operations."""
    # Set DOUT
    code, msg = robot.set_dout(10, True)
    assert code == 0
    
    # Get DOUT
    value = robot.get_dout(10)
    assert value == 1


def test_simulated_robot_set_tool(robot):
    """Test setting tool number."""
    code, msg = robot.set_tool(3)
    
    assert code == 0
    assert robot.tool_num == 3


def test_simulated_robot_get_tool(robot):
    """Test getting tool number."""
    robot.tool_num = 5
    
    code, msg = robot.get_tool()
    
    assert code == 0
    assert msg == "5"


def test_simulated_robot_set_user(robot):
    """Test setting user frame."""
    code, msg = robot.set_user(2)
    
    assert code == 0
    assert robot.user_frame == 2


def test_simulated_robot_get_user(robot):
    """Test getting user frame."""
    robot.user_frame = 4
    
    code, msg = robot.get_user()
    
    assert code == 0
    assert msg == "4"


def test_simulated_robot_set_coord(robot):
    """Test setting coordinate system."""
    code, msg = robot.set_coord("TOOL")
    
    assert code == 0
    assert robot.coord_system == "TOOL"


def test_simulated_robot_get_coord(robot):
    """Test getting coordinate system."""
    robot.coord_system = "USER"
    
    code, msg = robot.get_coord()
    
    assert code == 0
    assert msg == "USER"


def test_simulated_robot_get_power_consumption(robot):
    """Test getting power consumption."""
    power = robot.get_power_consumption()
    
    assert isinstance(power, float)
    assert power > 0

