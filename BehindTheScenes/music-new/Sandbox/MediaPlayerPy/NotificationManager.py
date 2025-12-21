from PySide6.QtCore import QObject, Signal, Slot

class NotificationManager(QObject):
    # This signal is what QML "listens" for
    notificationReceived = Signal(str, bool)

    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(NotificationManager, cls).__new__(cls)
        return cls._instance

    @Slot(str, bool)
    def post_notification(self, message, is_urgent=False):
        self.notificationReceived.emit(message, is_urgent)

# Global instance
notifier = NotificationManager()