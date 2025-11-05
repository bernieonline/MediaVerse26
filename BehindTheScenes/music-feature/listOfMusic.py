# this program willtake the name of a network share and search it for music files
# it returns this data
#/run/user/1000/gvfs/smb-share:server=freenas.local,share=movies/Collection/Music FLAC Bootleg/Mark Knopfler/2001-05-20, Los Angeles CA/14 Telegraph Road.flac

import os

# Define the path to your mounted network share
share_path = '/run/user/1000/gvfs/smb-share:server=freenas.local,share=movies'

# Define the music file extensions you want to search for
music_extensions = ('.mp3', '.flac', '.wav')

# Walk through the directory and list all music files
for root, dirs, files in os.walk(share_path):
    for file in files:
        if file.endswith(music_extensions):
            print(os.path.join(root, file))
