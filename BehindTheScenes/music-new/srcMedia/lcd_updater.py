import psutil
from PyQt5.QtCore import QTimer, QObject

class LCDUpdater(QObject):
    def __init__(self, cpu_lcd, ram_lcd, lan_lcd, parent=None):
        super().__init__(parent)
        self.cpu_lcd = cpu_lcd
        self.ram_lcd = ram_lcd
        self.lan_lcd = lan_lcd

        # Initialize previous bytes sent and received
        self.prev_bytes_sent = psutil.net_io_counters().bytes_sent
        self.prev_bytes_recv = psutil.net_io_counters().bytes_recv

        # Create a QTimer to update the LCDs every 5 seconds
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_lcds)
        self.timer.start(5000)  # 5000 milliseconds = 5 seconds

    def update_lcds(self):
        # Update CPU usage
        cpu_usage = psutil.cpu_percent(interval=1)
        self.cpu_lcd.display(cpu_usage)

        # Update available RAM in GB
        available_ram_gb = psutil.virtual_memory().available / (1024 ** 3)  # Convert bytes to GB
        self.ram_lcd.display(available_ram_gb)

         # Calculate network usage over the last 5 seconds
        current_bytes_sent = psutil.net_io_counters().bytes_sent
        current_bytes_recv = psutil.net_io_counters().bytes_recv

        # Calculate the difference in bytes sent and received
        bytes_sent_diff = current_bytes_sent - self.prev_bytes_sent
        bytes_recv_diff = current_bytes_recv - self.prev_bytes_recv

        # Update previous bytes sent and received
        self.prev_bytes_sent = current_bytes_sent
        self.prev_bytes_recv = current_bytes_recv

        # Convert to MB/s
        lan_usage_mb_s = (bytes_sent_diff + bytes_recv_diff) / (1024 * 1024 * 5)  # Divide by 5 seconds

        # Display the network usage in MB/s
        self.lan_lcd.display(lan_usage_mb_s)