# this returns a list of samba share names on freenas system

import subprocess

def get_samba_shares(nas_ip, username, password):
    result = subprocess.run(
        ['smbclient', '-L', f'//{nas_ip}', '-U', f'{username}%{password}'],
        capture_output=True, text=True, check=True
    )

    shares = {}
    in_shares_section = False
    for line in result.stdout.split('\n'):
        if "Sharename" in line:
            in_shares_section = True
        elif in_shares_section and not line.strip():
            in_shares_section = False
        elif in_shares_section:
            parts = line.split()
            if parts:
                share = parts[0]
                shares[share] = "Available"

    return shares

# Example usage

nas_ip = '192.168.1.229'
username = 'localBG'
password = 'LMA2019'
samba_shares = get_samba_shares(nas_ip, username, password)

print(samba_shares)

