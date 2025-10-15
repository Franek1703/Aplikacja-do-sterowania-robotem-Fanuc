#!/usr/bin/env python
"""
Command-line tool for controlling tool, user frame, and coordinate system
on Fanuc robots through fanucpy library.
"""

import argparse
import sys
from typing import Optional, Literal

from fanucpy.robot import Robot


def main() -> int:
    """Main function to parse arguments and execute commands."""
    parser = argparse.ArgumentParser(
        description="Control tool, user frame, and coordinate system on Fanuc robots"
    )
    
    # Connection parameters
    parser.add_argument("--host", type=str, required=True, help="Robot IP address")
    parser.add_argument("--port", type=int, default=18735, help="Robot port (default: 18735)")
    
    # Create subparsers for different commands
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # SET_TOOL command
    set_tool_parser = subparsers.add_parser("set_tool", help="Set tool number")
    set_tool_parser.add_argument("number", type=int, help="Tool number to set")
    
    # SET_USER command
    set_user_parser = subparsers.add_parser("set_user", help="Set user frame number")
    set_user_parser.add_argument("number", type=int, help="User frame number to set")
    
    # SET_COORD command
    set_coord_parser = subparsers.add_parser("set_coord", help="Set coordinate system")
    set_coord_parser.add_argument(
        "type", 
        type=str, 
        choices=["WORLD", "USER", "TOOL"],
        help="Coordinate system type (WORLD, USER, or TOOL)"
    )
    
    # GET commands
    subparsers.add_parser("get_tool", help="Get current tool number")
    subparsers.add_parser("get_user", help="Get current user frame number")
    subparsers.add_parser("get_coord", help="Get current coordinate system")
    
    # Parse arguments
    args = parser.parse_args()
    
    # Check if a command was provided
    if args.command is None:
        parser.print_help()
        return 1
    
    try:
        # Connect to robot
        robot = Robot(
            robot_model="Fanuc",
            host=args.host,
            port=args.port
        )
        
        robot.connect()
        
        # Execute the requested command
        if args.command == "set_tool":
            code, msg = robot.set_tool(args.number)
            print(f"Result: {msg}")
        elif args.command == "set_user":
            code, msg = robot.set_user(args.number)
            print(f"Result: {msg}")
        elif args.command == "set_coord":
            code, msg = robot.set_coord(args.type)
            print(f"Result: {msg}")
        elif args.command == "get_tool":
            code, tool_num = robot.get_tool()
            print(f"Current tool number: {tool_num}")
        elif args.command == "get_user":
            code, user_num = robot.get_user()
            print(f"Current user frame number: {user_num}")
        elif args.command == "get_coord":
            code, coord_type = robot.get_coord()
            print(f"Current coordinate system: {coord_type}")
        
        # Disconnect
        robot.disconnect()
        return 0
        
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())