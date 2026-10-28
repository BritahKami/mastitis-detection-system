from datetime import datetime, timedelta
from typing import Optional, Dict, Any

class ActiveTestSessionManager:
    """
    Manages active diagnostic test sessions between the Mobile UI and ESP32.
    """
    def __init__(self, session_timeout_minutes: int = 3):
        self.timeout_minutes = session_timeout_minutes
        self._active_session: Optional[Dict[str, Any]] = None

    def start_session(self, cow_id: int, cow_tag: str) -> Dict[str, Any]:
        """Locks incoming ESP32 readings to the specified cow for 3 minutes."""
        now = datetime.now()
        expires_at = now + timedelta(minutes=self.timeout_minutes)
        
        self._active_session = {
            "cow_id": cow_id,
            "cow_tag": cow_tag,
            "started_at": now,
            "expires_at": expires_at
        }
        return self._active_session

    def get_active_cow_id(self) -> Optional[int]:
        """Returns active cow_id if lock exists and has not expired."""
        if self._active_session is None:
            return None

        if datetime.now() > self._active_session["expires_at"]:
            self._active_session = None  # Lock expired
            return None

        return self._active_session["cow_id"]

    def clear_session(self) -> None:
        """Clears lock after reading is successfully processed."""
        self._active_session = None

# Global singleton
session_manager = ActiveTestSessionManager(session_timeout_minutes=3)