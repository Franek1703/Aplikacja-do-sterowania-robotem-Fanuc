"""
Example script demonstrating the extended FTP functionality for Fanuc robots.
This example shows how to use the new file and directory operations.
"""

import os
import sys
from pathlib import Path

# Add the parent directory to the path so we can import the robot module
sys.path.append(str(Path(__file__).parent.parent))

from robot.ftp import RobotFTP


def main():
    """Main function demonstrating the FTP functionality."""
    
    # Initialize the FTP client
    robot_ip = "192.168.56.8"  # Replace with your robot's IP address
    ftp = RobotFTP(
        host=robot_ip,
        user="FZ",  # Replace with your username if needed
        password="FANUC"        # Replace with your password if needed
    )
    device = "mc:"
    
    try:
        # Connect to the robot's FTP server
        print(f"Connecting to FTP server at {robot_ip}...")
        ftp.connect()
        print("Connected!")

        # Get all root folders
        ftp.change_directory(" ")
        pwd = ftp.get_pwd()
        print(f"\nDirectory changed successfully to {pwd}")

        print("\nListing root directories:")
        root_dirs = ftp.list_files("", "*", "ALL", change_dir=False)
        for file_info in root_dirs:
            if file_info.is_dir:
                print(f"  Directory: {file_info.name:<20} (modified: {file_info.modify_time})")
            else:
                print(f"  File: {file_info.name:<20} ({file_info.size:>6} bytes, modified: {file_info.modify_time})")

        # Create a new test directory
        pwd = ftp.get_pwd()
        print(f"\nCurrent directory: {pwd}")
        test_dir = f"{device}\\TEST_DIR"

        print(f"\nCreating directory: {test_dir}")
        try:
            ftp.create_directory(test_dir)
            print(f"Created directory: {test_dir}")
        except Exception as e:
            print(f"Note: {e} (Directory might already exist)")

        # Change to the test directory
        print(f"\nChanging to directory: {test_dir}")
        ftp.change_directory(test_dir)

        # Get the current directory again to confirm
        pwd = ftp.get_pwd()
        print(f"Current directory: {pwd}")

        # Create a simple TP program
        tp_program_content = """
/PROG  TEST_PROG
/ATTR
OWNER       = MNEDITOR;
COMMENT     = "Test program created by FTP";
PROG_SIZE   = 323;
CREATE      = DATE 23-10-15  TIME 10:00:00;
MODIFIED    = DATE 23-10-15  TIME 10:00:00;
FILE_NAME   = ;
VERSION     = 0;
LINE_COUNT  = 5;
MEMORY_SIZE = 743;
PROTECT     = READ_WRITE;
TCD:  STACK_SIZE    = 0,
      TASK_PRIORITY = 50,
      TIME_SLICE    = 0,
      BUSY_LAMP_OFF = 0,
      ABORT_REQUEST = 0,
      PAUSE_REQUEST = 0;
DEFAULT_GROUP   = 1,*,*,*,*;
CONTROL_CODE    = 00000000 00000000;
/MN
   1:  ! Test program created by FTP ;
   2:  ! This is an example ;
   3:  ! End of program ;
/POS
/END
"""

        # Write the program to the FTP server
        print("\nCreating a test TP program...")
        ftp.write_text_file(device=test_dir, filename="TEST_PROG.TP", content=tp_program_content)
        print("Created TEST_PROG.TP")
        
        # List files in the current directory
        print("\nListing files in the test directory:")
        test_files = ftp.list_files(test_dir, "*", "ALL")
        for file_info in test_files:
            if file_info.is_dir:
                print(f"  Directory: {file_info.name:<20} (modified: {file_info.modify_time})")
            else:
                print(f"  File: {file_info.name:<20} ({file_info.size:>6} bytes, modified: {file_info.modify_time})")
        
        # Rename the file
        print("\nRenaming TEST_PROG.TP to TEST_PROG_RENAMED.TP")
        try:
            ftp.rename_file("TEST_PROG.TP", "TEST_PROG_RENAMED.TP")
            print("File renamed successfully")
        except Exception as e:
            print(f"Failed to rename file: {e}")
        
        # Read the renamed file
        print("\nReading the renamed file:")
        try:
            content = ftp.read_file(test_dir, "TEST_PROG_RENAMED.TP")
            # Print first few lines
            lines = content.split('\n')
            print(f"First 5 lines of the file:")
            for i, line in enumerate(lines[:5]):
                print(f"  {i+1}: {line}")
        except Exception as e:
            print(f"Failed to read file: {e}")
        
        # Create a local download directory
        local_download_dir = os.path.join(os.path.dirname(__file__), "downloads")
        os.makedirs(local_download_dir, exist_ok=True)
        
        # Download the file to the local filesystem
        local_path = os.path.join(local_download_dir, "TEST_PROG_DOWNLOADED.TP")
        print(f"\nDownloading file to {local_path}")
        try:
            ftp.download_binary_file("TEST_PROG_RENAMED.TP", local_path)
            print("File downloaded successfully")
            print(f"Local file size: {os.path.getsize(local_path)} bytes")
        except Exception as e:
            print(f"Failed to download file: {e}")
        
        # Clean up - delete the test file
        print("\nCleaning up...")
        try:
            ftp.remove_file("TEST_PROG_RENAMED.TP")
            print("Removed test file")
        except Exception as e:
            print(f"Failed to remove file: {e}")

        # Go back to root directory
        print("\nGoing back to root directory")
        ftp.change_directory("/")
        
        # Try to remove the test directory
        print(f"Removing test directory: {test_dir}")
        try:
            ftp.remove_directory(test_dir)
            print("Test directory removed")
        except Exception as e:
            print(f"Note: Failed to remove directory: {e}")
            print("This is normal if the directory is not empty")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Disconnect from the FTP server
        ftp.disconnect()
        print("\nDisconnected from FTP server")


if __name__ == "__main__":
    main()