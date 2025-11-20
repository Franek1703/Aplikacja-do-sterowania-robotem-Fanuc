"""
Parser for FANUC robot alarm log files.

This module provides functionality to parse different alarm log formats
and convert them into structured Alarm objects.
"""

import re
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)


@dataclass
class Alarm:
    """Data model for a FANUC robot alarm entry.
    
    Attributes:
        alarm_number: Unique alarm number (or sequence number for ERREXT format)
        timestamp: Date and time when the alarm occurred
        alarm_code: Alarm code (e.g., SRVO-003, INTP-311, PROG-048)
        message: Main alarm message/description
        cause_message: Optional secondary message explaining the cause
        severity: Severity level (SERVO, WARN, STOP.L, ABORT.L, etc.)
        flags: Status flags in hexadecimal format
        action_required: Optional action requirement indicator (e.g., "act")
        raw_line: Original raw line from the log file
    """
    alarm_number: str
    timestamp: Optional[datetime]
    alarm_code: str
    message: str
    cause_message: Optional[str]
    severity: str
    flags: Optional[str]
    action_required: Optional[str]
    raw_line: str
    
    def __str__(self) -> str:
        """String representation of the alarm."""
        time_str = self.timestamp.strftime("%d-%b-%y %H:%M") if self.timestamp else "Unknown"
        cause = f" | Cause: {self.cause_message}" if self.cause_message else ""
        action = f" [ACTION: {self.action_required}]" if self.action_required else ""
        return f"[{self.alarm_number}] {time_str} | {self.alarm_code} {self.message} | {self.severity}{cause}{action}"
    
    def __repr__(self) -> str:
        """Detailed representation of the alarm."""
        return f"Alarm(number={self.alarm_number}, code={self.alarm_code}, severity={self.severity}, message='{self.message[:30]}...')"


class AlarmLogParser:
    """Parser for FANUC alarm log files."""
    
    # Pattern for standard alarm format (ERRALL, ERRSYS, ERRMOT, etc.)
    # Example: 231164" 04-NOV-25 15:20 " SRVO-003 Deadman switch released                  " " SERVO                         00110110" act"
    STANDARD_PATTERN = re.compile(
        r'^(?P<alarm_number>\d+)"\s*'
        r'(?P<date>\d{2}-[A-Z]{3}-\d{2})\s+'
        r'(?P<time>\d{2}:\d{2})\s*"\s*'
        r'(?P<alarm_code>[A-Z]{4}-\d{3})\s+'
        r'(?P<message>[^"]+?)\s*"\s*'
        r'(?P<cause_message>[^"]*?)\s*"\s*'
        r'(?P<severity>\S+)\s+'
        r'(?P<flags>[0-9A-F]{8})"\s*'
        r'(?P<action>.*?)$'
    )
    
    # Pattern for extended alarm format (ERREXT)
    # Example:  1    " 04-NOV-25 15:20 " SRVO-003 Deadman switch released                   "                                                    " SERVO   "
    EXTENDED_PATTERN = re.compile(
        r'^\s*(?P<sequence>\d+)\s+"\s*'
        r'(?P<date>\d{2}-[A-Z]{3}-\d{2})\s+'
        r'(?P<time>\d{2}:\d{2})\s*"\s*'
        r'(?P<alarm_code>[A-Z]{4}-\d{3})\s+'
        r'(?P<message>[^"]+?)\s*"\s*'
        r'(?P<cause_message>[^"]*?)\s*"\s*'
        r'(?P<severity>\S*)\s*"'
    )
    
    # Pattern for RESET entries
    RESET_PATTERN = re.compile(
        r'^(?P<alarm_number>\d+)"\s*'
        r'(?P<date>\d{2}-[A-Z]{3}-\d{2})\s+'
        r'(?P<time>\d{2}:\d{2})\s*"\s*'
        r'R\s+E\s+S\s+E\s+T\s*"\s*"\s*'
        r'(?P<flags>[0-9A-F]{8})'
    )
    
    @staticmethod
    def parse_timestamp(date_str: str, time_str: str) -> Optional[datetime]:
        """Parse date and time strings into a datetime object.
        
        Args:
            date_str: Date string in format DD-MMM-YY (e.g., "04-NOV-25")
            time_str: Time string in format HH:MM (e.g., "15:20")
            
        Returns:
            datetime object or None if parsing fails
        """
        try:
            # Combine date and time, add seconds
            datetime_str = f"{date_str} {time_str}:00"
            # Parse with format: DD-MMM-YY HH:MM:SS
            return datetime.strptime(datetime_str, "%d-%b-%y %H:%M:%S")
        except ValueError as e:
            logger.warning(f"Failed to parse timestamp '{date_str} {time_str}': {e}")
            return None
    
    @classmethod
    def parse_line(cls, line: str) -> Optional[Alarm]:
        """Parse a single line from an alarm log file.
        
        Args:
            line: A single line from the alarm log
            
        Returns:
            An Alarm object if parsing succeeds, None otherwise
        """
        line = line.strip()
        
        # Skip empty lines and header lines
        if not line or line.startswith(('ERR', 'F Number:', '$VERSION:', '$FEATURE')):
            return None
        
        # Try standard pattern first
        match = cls.STANDARD_PATTERN.match(line)
        if match:
            groups = match.groupdict()
            timestamp = cls.parse_timestamp(groups['date'], groups['time'])
            
            return Alarm(
                alarm_number=groups['alarm_number'],
                timestamp=timestamp,
                alarm_code=groups['alarm_code'],
                message=groups['message'].strip(),
                cause_message=groups['cause_message'].strip() or None,
                severity=groups['severity'].strip(),
                flags=groups['flags'],
                action_required=groups['action'].strip() or None,
                raw_line=line
            )
        
        # Try extended pattern
        match = cls.EXTENDED_PATTERN.match(line)
        if match:
            groups = match.groupdict()
            timestamp = cls.parse_timestamp(groups['date'], groups['time'])
            
            return Alarm(
                alarm_number=groups['sequence'],
                timestamp=timestamp,
                alarm_code=groups['alarm_code'],
                message=groups['message'].strip(),
                cause_message=groups['cause_message'].strip() or None,
                severity=groups['severity'].strip(),
                flags=None,
                action_required=None,
                raw_line=line
            )
        
        # Try RESET pattern
        match = cls.RESET_PATTERN.match(line)
        if match:
            groups = match.groupdict()
            timestamp = cls.parse_timestamp(groups['date'], groups['time'])
            
            return Alarm(
                alarm_number=groups['alarm_number'],
                timestamp=timestamp,
                alarm_code="RESET",
                message="R E S E T",
                cause_message=None,
                severity="SYSTEM",
                flags=groups['flags'],
                action_required=None,
                raw_line=line
            )
        
        # If no pattern matches, log it for debugging
        logger.debug(f"Could not parse line: {line[:100]}")
        return None
    
    @classmethod
    def parse_log(cls, log_content: str) -> List[Alarm]:
        """Parse an entire alarm log file content.
        
        Args:
            log_content: The complete content of an alarm log file
            
        Returns:
            A list of Alarm objects
        """
        alarms = []
        lines = log_content.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            try:
                alarm = cls.parse_line(line)
                if alarm:
                    alarms.append(alarm)
            except Exception as e:
                logger.warning(f"Error parsing line {line_num}: {e}")
                continue
        
        logger.info(f"Parsed {len(alarms)} alarms from {len(lines)} lines")
        return alarms
    
    @staticmethod
    def filter_by_severity(alarms: List[Alarm], severities: List[str]) -> List[Alarm]:
        """Filter alarms by severity level.
        
        Args:
            alarms: List of Alarm objects
            severities: List of severity strings to filter by (e.g., ["SERVO", "ABORT.L"])
            
        Returns:
            Filtered list of alarms
        """
        severities_upper = [s.upper() for s in severities]
        return [alarm for alarm in alarms if alarm.severity.upper() in severities_upper]
    
    @staticmethod
    def filter_by_code_prefix(alarms: List[Alarm], prefix: str) -> List[Alarm]:
        """Filter alarms by alarm code prefix.
        
        Args:
            alarms: List of Alarm objects
            prefix: Alarm code prefix to filter by (e.g., "SRVO", "INTP")
            
        Returns:
            Filtered list of alarms
        """
        prefix_upper = prefix.upper()
        return [alarm for alarm in alarms if alarm.alarm_code.upper().startswith(prefix_upper)]
    
    @staticmethod
    def filter_by_date_range(
        alarms: List[Alarm],
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> List[Alarm]:
        """Filter alarms by date range.
        
        Args:
            alarms: List of Alarm objects
            start_date: Start date (inclusive), None means no lower bound
            end_date: End date (inclusive), None means no upper bound
            
        Returns:
            Filtered list of alarms
        """
        result = []
        for alarm in alarms:
            if alarm.timestamp is None:
                continue
            
            if start_date and alarm.timestamp < start_date:
                continue
            
            if end_date and alarm.timestamp > end_date:
                continue
            
            result.append(alarm)
        
        return result
    
    @staticmethod
    def get_alarm_summary(alarms: List[Alarm]) -> dict:
        """Generate a summary of alarms.
        
        Args:
            alarms: List of Alarm objects
            
        Returns:
            Dictionary with summary statistics
        """
        if not alarms:
            return {
                'total_count': 0,
                'by_severity': {},
                'by_code': {},
                'unique_codes': set()
            }
        
        by_severity = {}
        by_code = {}
        
        for alarm in alarms:
            # Count by severity
            severity = alarm.severity
            by_severity[severity] = by_severity.get(severity, 0) + 1
            
            # Count by alarm code
            code = alarm.alarm_code
            by_code[code] = by_code.get(code, 0) + 1
        
        return {
            'total_count': len(alarms),
            'by_severity': by_severity,
            'by_code': by_code,
            'unique_codes': set(by_code.keys())
        }

