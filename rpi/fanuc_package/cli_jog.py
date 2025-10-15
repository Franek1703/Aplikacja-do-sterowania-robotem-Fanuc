#!/usr/bin/env python
"""
Command-line tool for jogging (continuous movement control) of Fanuc robots
through fanucpy library. Provides iPendant-like controls for 6 DOF.
"""

import argparse
import sys
from typing import Literal, Optional

from fanucpy.robot import Robot


def main() -> int:
    """Main function to parse arguments and execute commands."""
    parser = argparse.ArgumentParser(
        description="Control jogging operations on Fanuc robots (iPendant-like controls)"
    )
    
    # Connection parameters
    parser.add_argument("--host", type=str, required=True, help="Robot IP address")
    parser.add_argument("--port", type=int, default=18735, help="Robot port (default: 18735)")
    
    # Create subparsers for different commands
    subparsers = parser.add_subparsers(dest="command", help="Jog command to execute")
    
    # START command
    start_parser = subparsers.add_parser("start", help="Start jogging an axis")
    start_parser.add_argument("--axis", type=str, required=True, choices=["X", "Y", "Z", "W", "P", "R"], 
                             help="Axis to jog (X, Y, Z, W, P, R)")
    start_parser.add_argument("--dir", type=str, required=True, choices=["+", "-"],
                             help="Direction to jog (+ or -)")
    start_parser.add_argument("--speed", type=int, default=None,
                             help="Speed percentage (1-100, default: 25%%)")
    start_parser.add_argument("--step", type=float, default=None,
                             help="Step size per tick (mm for XYZ, deg for WPR, default: 0.25mm/0.5deg)")
    
    # STOP command
    stop_parser = subparsers.add_parser("stop", help="Stop jogging a specific axis")
    stop_parser.add_argument("--axis", type=str, required=True, choices=["X", "Y", "Z", "W", "P", "R"],
                            help="Axis to stop jogging (X, Y, Z, W, P, R)")
    
    # STOP-ALL command
    subparsers.add_parser("stop-all", help="Stop all jogging operations")
    
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
        if args.command == "start":
            code, msg = robot.jog_start(args.axis, args.dir, args.speed, args.step)
            print(f"Started jogging {args.axis}{args.dir}: {msg}")
        elif args.command == "stop":
            code, msg = robot.jog_stop(args.axis)
            print(f"Stopped jogging {args.axis}: {msg}")
        elif args.command == "stop-all":
            code, msg = robot.jog_stop_all()
            print(f"Stopped all jogging: {msg}")
        
        # Disconnect (only for stop commands, for start we keep connection)
        if args.command != "start":
            robot.disconnect()
        
        return 0
        
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())