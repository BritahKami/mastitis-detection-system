from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from zoneinfo import ZoneInfo

EAT_TZ = ZoneInfo("Africa/Nairobi")

class ActiveTestSessionManager:
    """
    Manages active diagnostic test sessions between the Mobile UI and ESP32.
    Enforces a 5-reading bounded window (or 3-minute timeout) per test session.
    """
    def __init__(self, session_timeout_minutes: int = 3, max_readings: int = 5):
        self.timeout_minutes = session_timeout_minutes
        self.max_readings = max_readings
        self._active_session: Optional[Dict[str, Any]] = None

    def start_session(self, cow_id: int, cow_tag: str, max_readings: Optional[int] = None) -> Dict[str, Any]:
        """Locks incoming ESP32 readings to the specified cow for up to max_readings (default 5) or 3 minutes."""
        now = datetime.now(EAT_TZ)
        expires_at = now + timedelta(minutes=self.timeout_minutes)
        limit = max_readings if max_readings is not None else self.max_readings
        
        self._active_session = {
            "cow_id": cow_id,
            "cow_tag": cow_tag,
            "started_at": now,
            "expires_at": expires_at,
            "reading_count": 0,
            "max_readings": limit,
            "latest_reading": None,
            "latest_result": None
        }
        return self._active_session

    def get_active_cow_id(self) -> Optional[int]:
        """Returns active cow_id if lock exists, has not expired, and has not reached max readings."""
        if self._active_session is None:
            return None

        if datetime.now(EAT_TZ) > self._active_session["expires_at"]:
            self._active_session = None  # Lock expired
            return None

        if self._active_session.get("reading_count", 0) >= self._active_session.get("max_readings", self.max_readings):
            self._active_session = None  # Reached 5-reading limit
            return None

        return self._active_session["cow_id"]

    def get_active_session(self) -> Optional[Dict[str, Any]]:
        """Returns active session dictionary if lock exists and has not expired or exceeded limit."""
        if self._active_session is None:
            return None

        if datetime.now(EAT_TZ) > self._active_session["expires_at"]:
            self._active_session = None
            return None

        if self._active_session.get("reading_count", 0) >= self._active_session.get("max_readings", self.max_readings):
            self._active_session = None
            return None

        return self._active_session

    def get_reading_count(self) -> int:
        """Returns current number of valid readings processed in active session."""
        if self._active_session is None:
            return 0
        return self._active_session.get("reading_count", 0)

    def record_reading(self, reading_data: Dict[str, Any]) -> int:
        """
        Records latest reading data, increments the valid reading counter,
        and automatically clears/closes the active test session lock once
        the max readings limit (5) is reached.
        Returns the updated reading count.
        """
        if self._active_session is None:
            return 0
        
        self._active_session["latest_reading"] = reading_data
        self._active_session["reading_count"] = self._active_session.get("reading_count", 0) + 1
        count = self._active_session["reading_count"]
        limit = self._active_session.get("max_readings", self.max_readings)

        if count >= limit:
            # Once the 5th valid reading is processed, automatically clear/close the active test session lock
            self._active_session = None

        return count

    def update_latest_reading(self, reading_data: Dict[str, Any]) -> None:
        """Keeps or updates the latest reading data during the session window."""
        if self._active_session is not None:
            self._active_session["latest_reading"] = reading_data

    def clear_session(self) -> None:
        """Clears session lock."""
        self._active_session = None

# Global singleton
session_manager = ActiveTestSessionManager(session_timeout_minutes=3, max_readings=5)