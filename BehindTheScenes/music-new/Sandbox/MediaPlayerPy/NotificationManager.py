from PySide6.QtCore import QObject, Signal, Slot

class NotificationManager(QObject):
    # This signal is what QML "listens" for
    notificationReceived = Signal(str, bool)

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(NotificationManager, cls).__new__(cls)
            cls._instance._qml_ready = False
            cls._instance._pending = []
        return cls._instance

    @Slot(str, bool)
    def post_notification(self, message, is_urgent=False):
        if not self._qml_ready:
            # QML not connected yet — buffer for replay
            self._pending.append((message, is_urgent))
            return
        self.notificationReceived.emit(message, is_urgent)

    @Slot()
    def flush_pending(self):
        """Call once after QML is loaded to replay any buffered startup messages."""
        self._qml_ready = True
        for message, is_urgent in self._pending:
            self.notificationReceived.emit(message, is_urgent)
        self._pending.clear()

# Global instance
notifier = NotificationManager()