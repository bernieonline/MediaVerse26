# this file takes credentails for a nas drive and returns a list of shares, select a share and it will list the top level contents



import subprocess


#this function takes creds and returns a list of shares
def get_samba_shares(nas_ip, username, password):
    result = subprocess.run(                                                                        #runs a subprocess or external command  called smbclient
        ['smbclient', '-L', f'//{nas_ip}', '-U', f'{username}%{password}'],                         #passing in credentials
        capture_output=True, text=True, check=True                                                  #capture_output is an option in subprocess that allows you to store the output in result as well as stderror
    )

    shares = []                                                     #create an array
    in_shares_section = False                                       # boolean flag
    for line in result.stdout.split('\n'):                          # loops through stdout splitting at new line
        if "Sharename" in line:                                     #looks to see if the word sharename is in the text of the line
            in_shares_section = True                                #flag=true
        elif in_shares_section and not line.strip():                #if after removing white space the text doesnt include sharename flag=false
            in_shares_section = False
        elif in_shares_section:                                     #checks to see if we are still in shares ection
            parts = line.split()                                    #if so split up the text into a list
            if parts:                                               # if there is text in the list
                share = parts[0]                                    #take the first item
                shares.append(share)                                #and append to share list

    return shares                                                   #return the list of sharenames



# having selected a share name we need to know what is in it
def list_files_in_share(nas_ip, username, password, share):
    try:
        result = subprocess.run(
            ['smbclient', f'//{nas_ip}/{share}', '-U', f'{username}%{password}', '-c', 'ls'],       #Run the smbclient command to list (ls) the contents of the specified share.
            capture_output=True, text=True, check=True
        )
        print(f"Files in {share}:")                                                                 #Print a header indicating which share’s files are being listed.
        print(result.stdout)                                                                        # Print the captured output, which contains the file list from the share.
    except Exception as e:
        print(f"An error occurred: {e}")

# Usage for WDDrive
#nas_ip = "192.168.1.205"
#username = "admin"
#password = "MyCloud2023###"

#usage for Freenas
nas_ip = "192.168.1.229"
username = "localBG"
password = "LMA2019"

# Get list of shares
shares = get_samba_shares(nas_ip, username, password)
print("Available Shares:")
for i, share in enumerate(shares):
    print(f"{i+1}. {share}")

# Select a share to view files
share_index = int(input("Enter the number of the share to view: ")) - 1
selected_share = shares[share_index]

# List files in the selected share
list_files_in_share(nas_ip, username, password, selected_share)
