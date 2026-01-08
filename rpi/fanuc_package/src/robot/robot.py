from __future__ import annotations

import socket
from typing import Literal, Union, List, Optional

from .ftp import RobotFTP, RobotFTPError


class FanucError(Exception):
    pass


class Robot:
    def __init__(
        self,
        robot_model: str,
        host: str,
        port: int = 18735,
        ee_DO_type: str | None = None,
        ee_DO_num: int | None = None,
        socket_timeout: int = 60,
        ftp_user: str = "anonymous",
        ftp_password: str = "",
    ):
        """Class to connect to the robot, send commands, and receive
        responses.

        Args:
            robot_model (str): Robot model: Fanuc, Kuka, etc.
            host (str): IP address of host.
            port (int): Port number. Defaults to 18735.
            ee_DO_type (str, optional): End-effector digital output
                type. Fanuc used RDO type. Defaults to None. Others may
                use DO type.
            ee_DO_num (int, optional): End-effector digital output
                number. Defaults to None.
            socket_timeout(int): Socket timeout in seconds. Defaults to
                5 seconds.
            ftp_user (str): FTP username. Defaults to "anonymous".
            ftp_password (str): FTP password. Defaults to "".
        """
        self.robot_model = robot_model
        self.host = host
        self.port = port
        self.ee_DO_type = ee_DO_type
        self.ee_DO_num = ee_DO_num
        self.sock_buff_sz = 1024
        self.socket_timeout = socket_timeout
        self.comm_sock: socket.socket
        self.SUCCESS_CODE = 0
        self.ERROR_CODE = 1
        
        # Initialize FTP client
        self.ftp = RobotFTP(host=host, user=ftp_user, password=ftp_password)

    def handle_response(
        self, resp: str, continue_on_error: bool = False
    ) -> tuple[Literal[0, 1], str]:
        """Handles response from socket communication.

        Args:
            resp (str): Response string returned from socket.
            verbose (bool, optional): [description]. Defaults to False.

        Returns:
            tuple(int, str): Response code and response message.
        """
        code_, msg = resp.split(":")
        code = int(code_)

        # Catch possible errors
        if code == self.ERROR_CODE and not continue_on_error:
            raise FanucError(msg)
        if code not in (self.SUCCESS_CODE, self.ERROR_CODE):
            raise FanucError(f"Unknown response code: {code} and message: {msg}")

        return code, msg  # type: ignore[return-value]

    def connect(self) -> tuple[Literal[0, 1], str]:
        """Connects to the physical robot."""
        self.comm_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.comm_sock.settimeout(self.socket_timeout)
        self.comm_sock.connect((self.host, self.port))
        resp = self.comm_sock.recv(self.sock_buff_sz).decode()
        return self.handle_response(resp)

    def disconnect(self) -> None:
        """Disconnect from the robot communication socket and FTP."""
        self.comm_sock.close()
        # Also disconnect from FTP if connected
        try:
            self.ftp.disconnect()
        except Exception:
            pass

    def send_cmd(
        self, cmd: str, continue_on_error: bool = False
    ) -> tuple[Literal[0, 1], str]:
        """Sends command to a physical robot.

        Args:
            cmd (str): Command string.

        Returns:
            tuple(int, str): Response code and response message.
        """
        # end of command character
        cmd = cmd.strip() + "\n"

        # Send command
        self.comm_sock.sendall(cmd.encode())

        # Wait for a result (blocking)
        resp = self.comm_sock.recv(self.sock_buff_sz).decode()
        return self.handle_response(resp=resp, continue_on_error=continue_on_error)

    def call_prog(self, prog_name: str) -> tuple[Literal[0, 1], str]:
        """Calls external program name in a physical robot.

        Args:
            prog_name ([str]): External program name.
        """
        cmd = f"fanuccall:{prog_name}"
        return self.send_cmd(cmd)

    def get_ins_power(self) -> float:
        """Gets instantaneous power consumption.

        Returns:
            float: Watts.
        """

        cmd = "ins_pwr"
        _, msg = self.send_cmd(cmd)

        # Fanuc returns in kW. Should be adjusted to other robots.
        ins_pwr = float(msg) * 1000

        return ins_pwr

    def get_curpos(self) -> list[float]:
        """Gets current cartesian position of tool center point.

        Returns:
            list[float]: Current positions XYZWPR.
        """

        cmd = "curpos"
        _, msg = self.send_cmd(cmd)
        vals = [float(val.split("=")[1]) for val in msg.split(",")]
        return vals

    def get_curjpos(self) -> list[float]:
        """Gets current joint values of tool center point.

        Returns:
            list[float]: Current joint values.
        """
        cmd = "curjpos"
        _, msg = self.send_cmd(cmd)
        vals = [float(val.split("=")[1]) for val in msg.split(",") if val != "j=none"]
        return vals

    def move(
        self,
        move_type: Literal["joint"] | Literal["pose"],
        vals: list,
        velocity: int = 25,
        acceleration: int = 100,
        cnt_val: int = 0,
        linear: bool = False,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Moves robot.

        Args:
            move_type (str): Movement type (joint or pose).
            vals (list[real]): Position values.
            velocity (int, optional): Percentage or mm/s. Defaults to
                25%.
            acceleration (int, optional): Percentage or mm/s^2. Defaults
                to 100%.
            cnt_val (int, optional): Continuous value for stopping.
                Defaults to 50.
            linear (bool, optioal): Linear movement. Defaults to False.

        Raises:
            ValueError: raised if movement type is not one of
                ("movej", "movep")
        """

        # prepare velocity. percentage or mm/s
        # format: aaaa, e.g.: 0001%, 0020%, 3000 mm/s
        velocity = int(velocity)
        velocity_ = f"{velocity:04}"

        # prepare acceleration. percentage or mm/s^2
        # format: aaaa, e.g.: 0001%, 0020%, 0100 mm/s^2
        acceleration = int(acceleration)
        acceleration_ = f"{acceleration:04}"

        # prepare CNT value
        # format: aaa, e.g.: 001, 020, 100
        cnt_val = int(cnt_val)
        if not (0 <= cnt_val <= 100):
            raise ValueError("Incorrect CNT value.")
        cnt_val_ = f"{cnt_val:03}"

        if move_type == "joint" or move_type == "movej":
            cmd = "movej"
        elif move_type == "pose" or move_type == "movep":
            cmd = "movep"
        else:
            raise ValueError("Incorrect movement type!")

        motion_type = int(linear)

        cmd += f":{velocity_}:{acceleration_}:{cnt_val_}:{motion_type}:{len(vals)}"

        # prepare joint values
        for val in vals:
            vs = f"{abs(val):013.6f}"
            if val >= 0:
                vs = "+" + vs
            else:
                vs = "-" + vs
            cmd += f":{vs}"

        # call send_cmd
        return self.send_cmd(cmd, continue_on_error=continue_on_error)

    def gripper(
        self,
        value: bool,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Opens/closes robot gripper.

        Args:
            value (bool): True or False
        """
        # if (self.ee_DO_type is not None) and (self.ee_DO_num is not None):
        #     cmd = ""
        #     if self.ee_DO_type == "RDO":
        #         cmd = "setrdo"
        #         port = str(self.ee_DO_num)
        #     elif self.ee_DO_type == "DO":
        #         cmd = "setdout"
        #         port = str(self.ee_DO_num).zfill(5)
        #     else:
        #         raise ValueError("Wrong DO type!")

        #     cmd = cmd + f":{port}:{str(value).lower()}"
        #     return self.send_cmd(cmd, continue_on_error=continue_on_error)
        # else:
        #     raise ValueError("DO type or number is None!")

        # Run TP program to control gripper OTWORZ/ ZAMKNIJ depends of value
        prog_name = "OTWORZ" if value else "ZAMKNIJ"
        return self.call_prog(prog_name)

    def get_rdo(self, rdo_num: int) -> int:
        """Get RDO value.

        Args:
            rdo_num (int): RDO number.

        Returns:
            rdo_value: RDO value.
        """
        cmd = f"getrdo:{rdo_num}"
        _, rdo_value_ = self.send_cmd(cmd)
        rdo_value = int(rdo_value_)
        return rdo_value

    def set_rdo(
        self,
        rdo_num: int,
        val: bool,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Sets RDO value.

        Args:
            rdo_num (int): RDO number.
            val (bool): Value.
        """
        cmd = f"setrdo:{rdo_num}:{str(val).lower()}"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)

    def get_dout(self, dout_num: int) -> int:
        """Get DOUT value.

        Args:
            dout_num (int): DOUT number.

        Returns:
            dout_value: DOUT value.
        """
        cmd = f"getdout:{str(dout_num).zfill(5)}"
        _, dout_value_ = self.send_cmd(cmd)
        dout_value = int(dout_value_)
        return dout_value

    def set_dout(
        self,
        dout_num: int,
        val: bool,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Sets DOUT value.

        Args:
            dout_num (int): DOUT number.
            val (bool): Value.
        """
        cmd = f"setdout:{str(dout_num).zfill(5)}:{str(val).lower()}"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)

    def set_sys_var(
        self,
        sys_var: str,
        val: bool,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Sets system variable to True or False.

        Args:
            sys_var (str): System variable name.
            val (bool): Value.
        """
        val_ = "T" if val else "F"
        cmd = f"setsysvar:{sys_var}:{val_}"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
        
    def set_tool(
        self,
        tool_num: int,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Set tool number (UTOOL_NUM).
        
        Args:
            tool_num (int): Tool number to set
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
        """
        cmd = f"set_tool:{tool_num}"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
    
    def set_user(
        self,
        user_num: int,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Set user frame number (UFRAME_NUM).
        
        Args:
            user_num (int): User frame number to set
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
        """
        cmd = f"set_user:{user_num}"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
    
    def set_coord(
        self,
        coord_type: Literal["WORLD", "USER", "TOOL"],
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Set coordinate system.
        
        Args:
            coord_type (str): Coordinate system to use ("WORLD", "USER", or "TOOL")
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
        """
        if coord_type not in ("WORLD", "USER", "TOOL"):
            raise ValueError("Coordinate system must be WORLD, USER, or TOOL")
        cmd = f"set_coord:{coord_type}"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
    
    def get_tool(
        self,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Get current tool number (UTOOL_NUM).
        
        Args:
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
            Message contains the current tool number.
        """
        cmd = "get_tool"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
    
    def get_user(
        self,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Get current user frame number (UFRAME_NUM).
        
        Args:
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
            Message contains the current user frame number.
        """
        cmd = "get_user"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
    
    def get_coord(
        self,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Get current coordinate system.
        
        Args:
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
            Message contains the current coordinate system (WORLD, USER, or TOOL).
        """
        cmd = "get_coord"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
        
    def jog_start(
        self,
        axis: Literal["X", "Y", "Z", "W", "P", "R"],
        direction: Literal["+", "-"],
        speed: int = None,
        step: float = None,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Start continuous jogging of an axis.
        
        Args:
            axis (str): Axis to jog ("X", "Y", "Z", "W", "P", "R")
            direction (str): Direction ("+" or "-")
            speed (int, optional): Speed percentage (1-100). Defaults to 25%.
            step (float, optional): Step size per tick (mm for XYZ, deg for WPR).
                Defaults to 0.25mm for XYZ, 0.5deg for WPR.
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
        """
        if axis not in ("X", "Y", "Z", "W", "P", "R"):
            raise ValueError("Axis must be X, Y, Z, W, P, or R")
        
        if direction not in ("+", "-"):
            raise ValueError("Direction must be + or -")
        
        cmd = f"jog_start:{axis}:{direction}"
        
        if speed is not None:
            cmd += f":{speed}"
            if step is not None:
                cmd += f":{step}"
        
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
    
    def jog_stop(
        self,
        axis: Literal["X", "Y", "Z", "W", "P", "R"],
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Stop jogging of a specific axis.
        
        Args:
            axis (str): Axis to stop jogging ("X", "Y", "Z", "W", "P", "R")
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
        """
        if axis not in ("X", "Y", "Z", "W", "P", "R"):
            raise ValueError("Axis must be X, Y, Z, W, P, or R")
            
        cmd = f"jog_stop:{axis}"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
    
    def jog_stop_all(
        self,
        continue_on_error: bool = False,
    ) -> tuple[Literal[0, 1], str]:
        """Stop all jogging operations.
        
        Args:
            continue_on_error (bool, optional): Whether to continue on error. Defaults to False.
            
        Returns:
            tuple(int, str): Response code and response message.
        """
        cmd = "jog_stop_all"
        return self.send_cmd(cmd, continue_on_error=continue_on_error)
    
    def list_programs(self, device: str = "MD", pattern: str = "*", types: str = "ALL") -> List[str]:
        """List program files on the robot.
        
        This method connects to the robot's FTP server and lists program files
        matching the specified criteria.
        
        Args:
            device (str): Device to list files from (e.g., "MD", "UD1"), defaults to "MD".
            pattern (str): File pattern to match, defaults to "*".
            types (str): Type of programs to list ("TP", "KAREL", or "ALL"), defaults to "ALL".
            
        Returns:
            List[str]: A list of program filenames.
            
        Raises:
            FanucError: If an error occurs during FTP operation.
        """
        try:
            self.ftp.connect()
            return self.ftp.list_files(device, pattern, types)
        except RobotFTPError as e:
            raise FanucError(f"Failed to list programs: {e}")
        finally:
            self.ftp.disconnect()
    
    def read_program(self, device: str, filename: str) -> str:
        """Read a program file from the robot.
        
        This method connects to the robot's FTP server and reads the content
        of the specified program file.
        
        Args:
            device (str): Device to read from (e.g., "MD", "UD1").
            filename (str): Name of the program file to read.
            
        Returns:
            str: The program file contents as a string.
            
        Raises:
            FanucError: If an error occurs during FTP operation.
        """
        try:
            self.ftp.connect()
            return self.ftp.read_file(device, filename)
        except RobotFTPError as e:
            raise FanucError(f"Failed to read program: {e}")
        finally:
            self.ftp.disconnect()


if __name__ == "__main__":
    robot = Robot(
        robot_model="Fanuc",
        host="10.211.55.3",
        port=18735,
        ee_DO_type="RDO",
        ee_DO_num=7,
    )

    robot.connect()

    # move in joint space
    robot.move(
        "joint",
        vals=[0, 0, 0, 0, 0, 0],
        velocity=100,
        acceleration=100,
        cnt_val=0,
        linear=not False,
    )
    print(robot.get_curpos())

    # move in cartesian space
    robot.move(
        "pose",
        vals=[350, 0, 280, -15, -90, -160],
        velocity=100,
        acceleration=100,
        cnt_val=0,
        linear=not False,
    )
