import numpy as np
from robot.robot import Robot
import time

robot = Robot(
    robot_model="ROBOT",
    host="192.168.56.8",
    port=18735,
    ee_DO_type="RDO",
    ee_DO_num=7,
)

robot.connect()

# get robot state
print("Current poses: ")
cur_pos = robot.get_curpos()
cur_jpos = robot.get_curjpos()
print(f"Current pose: {cur_pos}")
print(f"Current joints: {cur_jpos}")

# move in joint space
# robot.move(
#     "joint",
#     vals=np.array(cur_jpos) + 5,
#     velocity=100,
#     acceleration=100,
#     cnt_val=0,
#     linear=False,
# )
#
# print("Poses after moving: ")
# cur_pos = robot.get_curpos()
# cur_jpos = robot.get_curjpos()
# print(f"Current pose: {cur_pos}")
# print(f"Current joints: {cur_jpos}")

# print("get/set DOUT")
# print(robot.get_dout(123))
# robot.set_dout(123, True)
# print(robot.get_dout(123))
# Test frame controls
# print("\n=== Testing Frame Controls ===")
# print("Setting tool frame 9...")
# code, msg = robot.set_tool(9)
# print(f"Set tool result: {code}:{msg}")
#
# print("\nSetting user frame 9...")
# code, msg = robot.set_user(9)
# print(f"Set user result: {code}:{msg}")
#
print("\nSetting coordinate system to WORLD...")
code, msg = robot.set_coord("WORLD")
print(f"Set coordinate system result: {code}:{msg}")
#
# # Get current frame information
print("\nCurrent frame settings:")
_, tool = robot.get_tool()
_, user = robot.get_user()
_, coord = robot.get_coord()
print(f"Tool: {tool} | User: {user} | Coord: {coord}")
#
# Test jogging
# print("\n=== Testing Movement Controls ===")
# print("Starting X+ jog for 2 seconds...")
# robot.jog_start("X", "+", 25, 0.5)
# time.sleep(2)
# robot.jog_stop("X")
# print("Stopped X+ jog")
#
# print("Current poses: ")
# cur_pos = robot.get_curpos()
# cur_jpos = robot.get_curjpos()
# print(f"Current pose: {cur_pos}")
# print(f"Current joints: {cur_jpos}")

print("\nStarting Z+ jog for 4 seconds...")
robot.jog_start("X", "-", 100, 8.0)
print("\nStarting Z+ jog for 4 seconds...")
time.sleep(8)
robot.jog_stop("X")
print("Stopped Z+ jog")
#
# print("Current poses: ")
# cur_pos = robot.get_curpos()
# cur_jpos = robot.get_curjpos()
# print(f"Current pose: {cur_pos}")
# print(f"Current joints: {cur_jpos}")
#
# # Test gripper
# print("\n=== Testing Gripper ===")
# print(f"Get gripper state: {robot.get_rdo(7)}")
# print(f"Get gripper state: {robot.get_dout(1)}")
#
# # Stop all jogging and clean up
# print("\nStopping all jog operations...")
# robot.jog_stop_all()
# robot.disconnect()
print("\nDisconected")
time.sleep(2)