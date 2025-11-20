"""
Example script demonstrating how to read alarm logs from Fanuc robots.
This example shows how to use the read_alarm_logs method with different alarm log types.
"""

import sys
from pathlib import Path
from datetime import datetime

# Add the parent directory to the path so we can import the robot module
sys.path.append(str(Path(__file__).parent.parent))

from robot.ftp import RobotFTP, AlarmLogType
from robot.alarm_parser import AlarmLogParser


def print_separator(title: str = ""):
    """Print a separator line with an optional title."""
    if title:
        print(f"\n{'=' * 70}")
        print(f"  {title}")
        print('=' * 70)
    else:
        print('=' * 70)


def print_alarms_preview(alarms: list, max_count: int = 10):
    """Print a preview of the parsed alarms.
    
    Args:
        alarms: List of Alarm objects to display.
        max_count: Maximum number of alarms to show.
    """
    if not alarms:
        print("  (No alarms found)")
        return
    
    print(f"  Total alarms: {len(alarms)}")
    print(f"  Showing first {min(max_count, len(alarms))} alarms:\n")
    
    for i, alarm in enumerate(alarms[:max_count], 1):
        print(f"  {i:3}. {alarm}")
    
    if len(alarms) > max_count:
        print(f"\n  ... ({len(alarms) - max_count} more alarms)")


def main():
    """Main function demonstrating alarm log reading."""
    
    # Initialize the FTP client
    robot_ip = "192.168.56.8"  # Replace with your robot's IP address
    ftp = RobotFTP(
        host=robot_ip,
        user="FZ",      # Replace with your username if needed
        password="FANUC"  # Replace with your password if needed
    )
    
    try:
        # Connect to the robot's FTP server
        print(f"Connecting to FTP server at {robot_ip}...")
        ftp.connect()
        print("Connected!\n")
        
        # Read all alarm types - default behavior (now returns parsed Alarm objects)
        print_separator("Reading ALL alarm logs (ERRALL.LS) - DEFAULT")
        try:
            all_alarms = ftp.read_alarm_logs()  # Returns List[Alarm]
            print_alarms_preview(all_alarms)
            
            # Show summary
            if all_alarms:
                summary = AlarmLogParser.get_alarm_summary(all_alarms)
                print(f"\n  Alarm Summary:")
                print(f"    Unique codes: {len(summary['unique_codes'])}")
                print(f"    By severity: {summary['by_severity']}")
        except Exception as e:
            print(f"  Error: {e}")
        
        # Read system alarms
        print_separator("Reading SYSTEM alarm logs (ERRSYS.LS)")
        try:
            sys_alarms = ftp.read_alarm_logs(kind=AlarmLogType.SYS)
            print_alarms_preview(sys_alarms)
        except Exception as e:
            print(f"  Error: {e}")
        
        # Read motion/servo alarms
        print_separator("Reading MOTION alarm logs (ERRMOT.LS)")
        try:
            mot_alarms = ftp.read_alarm_logs(kind=AlarmLogType.MOT)
            print_alarms_preview(mot_alarms)
            
            # Show most common motion alarm codes
            if mot_alarms:
                summary = AlarmLogParser.get_alarm_summary(mot_alarms)
                print(f"\n  Most common codes:")
                for code, count in sorted(summary['by_code'].items(), key=lambda x: -x[1])[:5]:
                    print(f"    {code}: {count} times")
        except Exception as e:
            print(f"  Error: {e}")
        
        # Read communication alarms
        print_separator("Reading COMMUNICATION alarm logs (ERRCOMM.LS)")
        try:
            comm_alarms = ftp.read_alarm_logs(kind=AlarmLogType.COMM)
            print_alarms_preview(comm_alarms)
        except Exception as e:
            print(f"  Error: {e}")
        
        # Read application alarms
        print_separator("Reading APPLICATION alarm logs (ERRAPP.LS)")
        try:
            app_alarms = ftp.read_alarm_logs(kind=AlarmLogType.APP)
            print_alarms_preview(app_alarms)
        except Exception as e:
            print(f"  Error: {e}")
        
        # Read actual/current alarms
        print_separator("Reading ACTUAL/CURRENT alarm logs (ERRACT.LS)")
        try:
            act_alarms = ftp.read_alarm_logs(kind=AlarmLogType.ACT)
            print_alarms_preview(act_alarms)
        except Exception as e:
            print(f"  Error: {e}")
        
        # Read extended alarms
        print_separator("Reading EXTENDED alarm logs (ERREXT.LS)")
        try:
            ext_alarms = ftp.read_alarm_logs(kind=AlarmLogType.EXT)
            print_alarms_preview(ext_alarms, max_count=15)
        except Exception as e:
            print(f"  Error: {e}")
        
        # Demonstrate filtering capabilities
        print_separator("Filtering Alarms")
        if all_alarms:
            # Filter by severity
            print("\n  Filtering severe alarms (SERVO, STOP.L, ABORT.L):")
            severe = AlarmLogParser.filter_by_severity(all_alarms, ["SERVO", "STOP.L", "ABORT.L"])
            print(f"    Found {len(severe)} severe alarms")
            if severe:
                print(f"    Most recent: {severe[0]}")
            
            # Filter by code prefix
            print("\n  Filtering SRVO (Servo) alarms:")
            srvo = AlarmLogParser.filter_by_code_prefix(all_alarms, "SRVO")
            print(f"    Found {len(srvo)} SRVO alarms")
            
            # Filter by date (today)
            print("\n  Filtering today's alarms:")
            today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            today_alarms = AlarmLogParser.filter_by_date_range(all_alarms, start_date=today)
            print(f"    Found {len(today_alarms)} alarms from today")
            
            # Alarms requiring action
            action_required = [a for a in all_alarms if a.action_required]
            print(f"\n  Alarms requiring action: {len(action_required)}")
        
        print_separator()
        print("\nExample: Reading from a different device (UD1:)")
        print("# alarms_from_ud1 = ftp.read_alarm_logs(kind=AlarmLogType.ALL, device='UD1:')")
        
        print("\nExample: Advanced filtering")
        print("""
# Filter alarms by multiple criteria
severe_servo = AlarmLogParser.filter_by_severity(alarms, ["SERVO"])
recent_servo = AlarmLogParser.filter_by_date_range(severe_servo, start_date=today)

# Get summary statistics
summary = AlarmLogParser.get_alarm_summary(alarms)
print(f"Total: {summary['total_count']}")
print(f"By severity: {summary['by_severity']}")
print(f"Unique codes: {len(summary['unique_codes'])}")
        """)
        
    except Exception as e:
        print(f"\nError: {e}")
    finally:
        # Disconnect from the FTP server
        ftp.disconnect()
        print("\nDisconnected from FTP server")


if __name__ == "__main__":
    main()

