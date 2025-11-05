
import psutil
# this program pists local drives but not network drives
# output is Available drives: ['/dev/sda3', '/dev/sda2']
def drive_list():
    drives = []
    partitions = psutil.disk_partitions(all=True)
    for partition in partitions:
        # Filter out system mounts by checking the mount point
        if partition.fstype and 'loop' not in partition.device and not partition.mountpoint.startswith('/sys') and not partition.mountpoint.startswith('/proc') and not partition.mountpoint.startswith('/dev') and not partition.mountpoint.startswith('/run'):
            drives.append(partition.device)
    return drives

# Example usage
if __name__ == "__main__":
    available_drives = drive_list()
    print("Available drives:", available_drives)
