import subprocess
# this program lists the network shares on freeserve in the first part but I needed to know the ip address to run it
# the second part lists all ip addresses on home network ----- sudo apt install arp-scan


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

#the ouutput is 
#ARP Scan Results:

#Interface: enp2s0, type: EN10MB, MAC: e0:69:95:53:22:b7, IPv4: 192.168.1.95
#Starting arp-scan 1.9.7 with 256 hosts (https://github.com/royhills/arp-scan)
#192.168.1.65    ec:a9:07:10:ca:59       (Unknown)
#192.168.1.79    f8:4e:17:1d:83:f6       (Unknown)
#192.168.1.98    18:82:8c:70:f0:48       (Unknown)
#192.168.1.90    78:3e:53:78:bb:32       BSkyB Ltd
#192.168.1.108   a8:5e:45:b6:7c:7d       ASUSTek COMPUTER INC.
#192.168.1.121   d4:52:ee:9e:b7:88       (Unknown)
#192.168.1.144   44:fe:3b:98:a7:74       Arcadyan Corporation
#192.168.1.203   76:d0:2b:ea:5b:a1       (Unknown: locally administered)
#192.168.1.205   00:14:ee:09:55:0d       Western Digital Technologies, Inc.
#192.168.1.229   74:d0:2b:7a:22:3c       ASUSTek COMPUTER INC.
#192.168.1.254   c8:99:b2:5f:24:1d       (Unknown)
#192.168.1.128   9e:12:ae:c8:e0:33       (Unknown: locally administered)
#192.168.1.106   48:e1:e9:22:61:df       Chengdu Meross Technology Co., Ltd.
#192.168.1.133   48:e1:e9:22:62:c9       Chengdu Meross Technology Co., Ltd.
#192.168.1.240   48:e1:e9:22:60:d8       Chengdu Meross Technology Co., Ltd.