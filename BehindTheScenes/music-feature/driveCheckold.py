#no longer used
import subprocess
# this program lists the network shares on freeserve
def list_smb_shares(nas_ip, username, password):
    try:
        # Run the smbclient command
        result = subprocess.run(
            ['smbclient', '-L', f'//{nas_ip}', '-U', f'{username}%{password}'],
            capture_output=True, text=True, check=True
        )
        # Print the output
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr}")

# Example usage
nas_ip = '192.168.1.229'
username = 'localBG'
password = 'LMA2019'
list_smb_shares(nas_ip, username, password)


#result
#Sharename       Type      Comment
#        ---------       ----      -------
#        IPC$            IPC       IPC Service (FreeNAS Server)
#        Movies          Disk      
#        backupFree      Disk      
#        Gaming4Back-Gaming4SnapBack-clone Disk      
#        Movies2         Disk      
#        test_share      Disk      
# SMB1 disabled -- no workgroup available

def run_arp_scan():
    try:
        # Run the arp-scan command
        result = subprocess.run(['sudo', 'arp-scan', '--localnet'], capture_output=True, text=True)
        # Check if the command was successful
        if result.returncode == 0:
            print("ARP Scan Results:\n")
            print(result.stdout)
        else:
            print("Error running arp-scan:\n")
            print(result.stderr)
    except Exception as e:
        print(f"An error occurred: {e}")
        
if __name__ == "__main__":
    run_arp_scan()