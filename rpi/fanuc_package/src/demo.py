import keyboard
import numpy as np
import time
import threading
import os
from robot.robot import Robot

def clear_screen():
    """Clear the terminal screen."""
    os.system('cls' if os.name == 'nt' else 'clear')

class InteractiveRobotControl:
    def __init__(self, robot_ip="192.168.56.8", port=18735):
        self.robot = Robot(
            robot_model="ROBOT",
            host=robot_ip,
            port=port,
            ee_DO_type="RDO",
            ee_DO_num=7,
        )
        self.running = False
        self.connected = False
        self.status_thread = None
        
        # Mapping of keys to functions
        self.key_mapping = {
            # Jogging controls - X, Y, Z, W, P, R axes
            'q': {'func': self.robot.jog_start, 'args': ["X", "+"], 'desc': "Jog X+"},
            'a': {'func': self.robot.jog_start, 'args': ["X", "-"], 'desc': "Jog X-"},
            'w': {'func': self.robot.jog_start, 'args': ["Y", "+"], 'desc': "Jog Y+"},
            's': {'func': self.robot.jog_start, 'args': ["Y", "-"], 'desc': "Jog Y-"},
            'e': {'func': self.robot.jog_start, 'args': ["Z", "+"], 'desc': "Jog Z+"},
            'd': {'func': self.robot.jog_start, 'args': ["Z", "-"], 'desc': "Jog Z-"},
            'r': {'func': self.robot.jog_start, 'args': ["W", "+"], 'desc': "Jog W+"},
            'f': {'func': self.robot.jog_start, 'args': ["W", "-"], 'desc': "Jog W-"},
            't': {'func': self.robot.jog_start, 'args': ["P", "+"], 'desc': "Jog P+"},
            'g': {'func': self.robot.jog_start, 'args': ["P", "-"], 'desc': "Jog P-"},
            'y': {'func': self.robot.jog_start, 'args': ["R", "+"], 'desc': "Jog R+"},
            'h': {'func': self.robot.jog_start, 'args': ["R", "-"], 'desc': "Jog R-"},
            
            # Jog stop
            'space': {'func': self.robot.jog_stop_all, 'args': [], 'desc': "Stop all jogging"},
            
            # Gripper control
            'o': {'func': self.robot.gripper, 'args': [True], 'desc': "Open gripper"},
            'c': {'func': self.robot.gripper, 'args': [False], 'desc': "Close gripper"},
            
            # Tool/User/Coord controls
            '1': {'func': self.set_tool_interactive, 'args': [], 'desc': "Set tool frame"},
            '2': {'func': self.set_user_interactive, 'args': [], 'desc': "Set user frame"},
            '3': {'func': self.set_coord_interactive, 'args': [], 'desc': "Set coordinate system"},
            '4': {'func': self.get_frames_info, 'args': [], 'desc': "Get frames info"},
            
            # Motion controls
            'm': {'func': self.move_joint_interactive, 'args': [], 'desc': "Move in joint space"},
            'n': {'func': self.move_pose_interactive, 'args': [], 'desc': "Move in pose space"},
            'i': {'func': self.increment_joint_pos, 'args': [], 'desc': "Increment joint values"},
            'p': {'func': self.increment_pose_pos, 'args': [], 'desc': "Increment pose values"},
            
            # Digital I/O
            '7': {'func': self.toggle_rdo, 'args': [], 'desc': "Toggle RDO"},
            '8': {'func': self.toggle_dout, 'args': [], 'desc': "Toggle DOUT"},
            
            # Utility commands
            'v': {'func': self.show_position, 'args': [], 'desc': "Show position"},
            'b': {'func': self.show_power, 'args': [], 'desc': "Show power consumption"},
            '0': {'func': self.call_program, 'args': [], 'desc': "Call external program"},
            
            # Connection control
            'z': {'func': self.connect_disconnect, 'args': [], 'desc': "Connect/Disconnect"},
            
            # Exit
            'esc': {'func': self.exit_program, 'args': [], 'desc': "Exit program"}
        }
        
        # Keep track of key states to avoid repeated calls
        self.key_states = {key: False for key in self.key_mapping.keys()}

    def connect_disconnect(self):
        """Toggle connection to the robot."""
        if not self.connected:
            try:
                self.robot.connect()
                self.connected = True
                print("Connected to robot successfully.")
            except Exception as e:
                print(f"Failed to connect: {e}")
        else:
            try:
                self.robot.disconnect()
                self.connected = False
                print("Disconnected from robot.")
            except Exception as e:
                print(f"Error during disconnection: {e}")
    
    def set_tool_interactive(self):
        """Interactively set tool frame."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        try:
            tool_num = int(input("Enter tool frame number (1-9): "))
            code, msg = self.robot.set_tool(tool_num)
            print(f"Set tool result: {code}:{msg}")
        except ValueError:
            print("Invalid input. Please enter a number.")
    
    def set_user_interactive(self):
        """Interactively set user frame."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        try:
            user_num = int(input("Enter user frame number (1-9): "))
            code, msg = self.robot.set_user(user_num)
            print(f"Set user result: {code}:{msg}")
        except ValueError:
            print("Invalid input. Please enter a number.")
    
    def set_coord_interactive(self):
        """Interactively set coordinate system."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        print("Available coordinate systems: WORLD, USER, TOOL")
        coord_type = input("Enter coordinate system: ").upper()
        if coord_type in ["WORLD", "USER", "TOOL"]:
            code, msg = self.robot.set_coord(coord_type)
            print(f"Set coord result: {code}:{msg}")
        else:
            print("Invalid coordinate system. Must be WORLD, USER, or TOOL.")
    
    def get_frames_info(self):
        """Get information about current tool, user frame, and coordinate system."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        code, tool_msg = self.robot.get_tool()
        code, user_msg = self.robot.get_user()
        code, coord_msg = self.robot.get_coord()
        
        print(f"Current tool: {tool_msg}")
        print(f"Current user frame: {user_msg}")
        print(f"Current coordinate system: {coord_msg}")
    
    def move_joint_interactive(self):
        """Interactively move the robot in joint space."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        try:
            print("Current joint positions:", self.robot.get_curjpos())
            joint_vals = input("Enter 6 joint values separated by spaces: ")
            vals = [float(x) for x in joint_vals.split()]
            
            if len(vals) != 6:
                print("Error: Must provide 6 joint values.")
                return
            
            vel = int(input("Velocity (1-100%): "))
            acc = int(input("Acceleration (1-100%): "))
            cnt = int(input("CNT value (0-100): "))
            linear = input("Linear motion (y/n): ").lower() == 'y'
            
            code, msg = self.robot.move("joint", vals, vel, acc, cnt, linear)
            print(f"Move result: {code}:{msg}")
        except ValueError:
            print("Invalid input. Please enter valid numbers.")
    
    def move_pose_interactive(self):
        """Interactively move the robot in pose space."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        try:
            print("Current pose:", self.robot.get_curpos())
            pose_vals = input("Enter 6 pose values (X Y Z W P R) separated by spaces: ")
            vals = [float(x) for x in pose_vals.split()]
            
            if len(vals) != 6:
                print("Error: Must provide 6 pose values.")
                return
            
            vel = int(input("Velocity (1-100%): "))
            acc = int(input("Acceleration (1-100%): "))
            cnt = int(input("CNT value (0-100): "))
            linear = input("Linear motion (y/n): ").lower() == 'y'
            
            code, msg = self.robot.move("pose", vals, vel, acc, cnt, linear)
            print(f"Move result: {code}:{msg}")
        except ValueError:
            print("Invalid input. Please enter valid numbers.")
    
    def increment_joint_pos(self):
        """Increment current joint position by small amounts."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        try:
            current_joints = self.robot.get_curjpos()
            print("Current joint positions:", current_joints)
            
            increment = float(input("Enter increment value for all joints: "))
            new_vals = [j + increment for j in current_joints]
            
            vel = int(input("Velocity (1-100%): "))
            
            code, msg = self.robot.move("joint", new_vals, vel, 100, 0, False)
            print(f"Move result: {code}:{msg}")
        except ValueError:
            print("Invalid input. Please enter valid numbers.")
    
    def increment_pose_pos(self):
        """Increment current pose position by small amounts."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        try:
            current_pose = self.robot.get_curpos()
            print("Current pose:", current_pose)
            
            axis = input("Which axis to increment (X,Y,Z,W,P,R) [0-5]: ")
            value = float(input("Enter increment value: "))
            
            new_vals = current_pose.copy()
            idx = "XYZWPR".index(axis) if axis in "XYZWPR" else int(axis)
            new_vals[idx] += value
            
            vel = int(input("Velocity (1-100%): "))
            linear = input("Linear motion (y/n): ").lower() == 'y'
            
            code, msg = self.robot.move("pose", new_vals, vel, 100, 0, linear)
            print(f"Move result: {code}:{msg}")
        except (ValueError, IndexError):
            print("Invalid input.")
    
    def toggle_rdo(self):
        """Toggle a Robot Digital Output (RDO)."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        try:
            rdo_num = int(input("Enter RDO number: "))
            current_state = self.robot.get_rdo(rdo_num)
            print(f"Current RDO {rdo_num} state: {current_state}")
            
            new_state = not bool(current_state)
            code, msg = self.robot.set_rdo(rdo_num, new_state)
            print(f"Set RDO {rdo_num} to {new_state}: {code}:{msg}")
        except ValueError:
            print("Invalid input. Please enter a valid number.")
    
    def toggle_dout(self):
        """Toggle a Digital Output (DOUT)."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        try:
            dout_num = int(input("Enter DOUT number: "))
            current_state = self.robot.get_dout(dout_num)
            print(f"Current DOUT {dout_num} state: {current_state}")
            
            new_state = not bool(current_state)
            code, msg = self.robot.set_dout(dout_num, new_state)
            print(f"Set DOUT {dout_num} to {new_state}: {code}:{msg}")
        except ValueError:
            print("Invalid input. Please enter a valid number.")
    
    def call_program(self):
        """Call an external program on the robot."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        prog_name = input("Enter program name to call: ")
        code, msg = self.robot.call_prog(prog_name)
        print(f"Call program result: {code}:{msg}")
    
    def show_position(self):
        """Show current robot position."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        print("Current joint positions:", self.robot.get_curjpos())
        print("Current pose:", self.robot.get_curpos())
    
    def show_power(self):
        """Show current power consumption."""
        if not self.connected:
            print("Not connected to robot.")
            return
        
        power = self.robot.get_ins_power()
        print(f"Current power consumption: {power:.2f} W")
    
    def exit_program(self):
        """Exit the program."""
        if self.connected:
            print("Disconnecting from robot...")
            self.robot.jog_stop_all()
            self.robot.disconnect()
        
        self.running = False
        print("Exiting...")
    
    def update_status(self):
        """Thread function to update status periodically."""
        while self.running:
            if not self.connected:
                time.sleep(1)
                continue
            
            try:
                clear_screen()
                print("=" * 50)
                print(" INTERACTIVE FANUC ROBOT CONTROL ")
                print("=" * 50)
                print(f"Connected: {'Yes' if self.connected else 'No'}")
                
                if self.connected:
                    try:
                        joint_pos = self.robot.get_curjpos()
                        cart_pos = self.robot.get_curpos()
                        
                        print("\nCURRENT POSITION:")
                        print(f"Joints: {joint_pos}")
                        print(f"Cartesian: {cart_pos}")
                        
                        # Try to get frames info
                        try:
                            _, tool_msg = self.robot.get_tool()
                            _, user_msg = self.robot.get_user()
                            _, coord_msg = self.robot.get_coord()
                            
                            print("\nFRAMES:")
                            print(f"Tool: {tool_msg} | User: {user_msg} | Coord: {coord_msg}")
                        except:
                            pass
                    except:
                        print("\nERROR: Could not read robot state")
                
                print("\nCONTROLS:")
                print("Movement: [Q/A] X±  [W/S] Y±  [E/D] Z±  [R/F] W±  [T/G] P±  [Y/H] R±")
                print("Gripper:  [O] Open  [C] Close")
                print("Frames:   [1] Set Tool  [2] Set User  [3] Set Coord  [4] Get Frames")
                print("Position: [V] Show Position  [B] Show Power")
                print("Motion:   [M] Move Joint  [N] Move Pose  [I] Increment Joint  [P] Increment Pose")
                print("I/O:      [7] Toggle RDO  [8] Toggle DOUT  [0] Call Program")
                print("Control:  [Z] Connect/Disconnect  [SPACE] Stop Jog  [ESC] Exit")
                
            except Exception as e:
                print(f"Status error: {e}")
            
            time.sleep(1)
    
    def key_press(self, e):
        """Handle key press events."""
        key = e.name
        if key in self.key_mapping and not self.key_states.get(key, False):
            if key in ['q', 'a', 'w', 's', 'e', 'd', 'r', 'f', 't', 'g', 'y', 'h'] and not self.connected:
                print("Not connected to robot.")
                return
            
            self.key_states[key] = True
            
            if self.connected:
                try:
                    func = self.key_mapping[key]['func']
                    args = self.key_mapping[key]['args']
                    func(*args)
                except Exception as e:
                    print(f"Error executing {self.key_mapping[key]['desc']}: {e}")
            elif key == 'z':  # Connect is allowed when disconnected
                self.connect_disconnect()
            elif key == 'esc':  # Exit is always allowed
                self.exit_program()
    
    def key_release(self, e):
        """Handle key release events."""
        key = e.name
        if key in self.key_mapping:
            self.key_states[key] = False
            
            # Handle jogging key releases - stop the corresponding axis
            jog_key_map = {
                'q': 'X', 'a': 'X', 
                'w': 'Y', 's': 'Y', 
                'e': 'Z', 'd': 'Z',
                'r': 'W', 'f': 'W',
                't': 'P', 'g': 'P',
                'y': 'R', 'h': 'R'
            }
            
            if key in jog_key_map and self.connected:
                try:
                    self.robot.jog_stop(jog_key_map[key])
                except Exception as e:
                    print(f"Error stopping jog: {e}")
    
    def run(self):
        """Run the interactive controller."""
        self.running = True
        
        # Start status thread
        self.status_thread = threading.Thread(target=self.update_status)
        self.status_thread.daemon = True
        self.status_thread.start()
        
        # Set up keyboard hooks
        keyboard.on_press(self.key_press)
        keyboard.on_release(self.key_release)
        
        print("Interactive controller started. Press ESC to exit.")
        
        try:
            # Keep main thread running
            while self.running:
                time.sleep(0.1)
        except KeyboardInterrupt:
            self.running = False
            if self.connected:
                self.robot.jog_stop_all()
                self.robot.disconnect()
        
        # Clean up
        keyboard.unhook_all()


if __name__ == "__main__":
    print("Starting Interactive FANUC Robot Control...")
    print("Initializing...")
    
    # Allow user to specify robot IP
    robot_ip = input("Enter robot IP (default: 192.168.56.8): ") or "192.168.56.8"
    
    controller = InteractiveRobotControl(robot_ip=robot_ip)
    controller.run()