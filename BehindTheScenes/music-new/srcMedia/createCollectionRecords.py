import os
import platform
import datetime

def traverse_folders(directory):
    media_files_data = []
    device_name = platform.node()

    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            file_size_mb = os.path.getsize(file_path) / (1024 * 1024)  # Convert bytes to MB
            file_creation_date = datetime.datetime.fromtimestamp(os.path.getctime(file_path))
            current_datetime = datetime.datetime.now()

            # Split file path and name
            pathname, filename = os.path.split(file_path)
            extension = os.path.splitext(filename)[1]

            # Create collection name
            media_type = extension.lstrip('.').lower()  # Remove dot and convert to lowercase
            collection_name = f"{media_type}_{current_datetime.strftime('%Y%m%d%H%M%S')}_{device_name}"

            # Prepare data for database
            media_file_info = {
                'device_name': device_name,
                'pathname': pathname,
                'filename': filename,
                'extension': extension,
                'file_size_mb': file_size_mb,
                'file_creation_date': file_creation_date,
                'record_creation_datetime': current_datetime,
                'collection_name': collection_name
            }

            media_files_data.append(media_file_info)

    return media_files_data




def search_media_files(start_path, media_type, master_record_type):
    """
    Searches for media files in the given directory path, filtering by media type,
    and prepares records for database insertion with the specified master record type.

    :param start_path: The directory path to begin the search.
    :param media_type: The type of media to filter (e.g., 'Video', 'Audio', 'Images').
    :param master_record_type: The type of master record (e.g., 'Master', 'Clone', 'Secondary').
    """
    device_name = platform.node()
    print(f"Creating media collection on device: {device_name}")
    start_time = time.time()

    # Fetch the list of media extensions and filter by the specified media type
    extensions = get_list_extensions()
    media_extensions = {ext.lower().strip() for type_, ext in extensions if type_ == media_type}

    # Fetch the list of exempt folders
    exempt_folders = set(get_list_folders())

    all_media_records = []  # Collect all media records for database insertion

    for dirpath, dirnames, filenames in os.walk(start_path):
        dirnames_lower = [d.lower() for d in dirnames]
        media_records = []  # Reset the list for each folder

        if os.path.basename(dirpath).lower() in exempt_folders:
            dirnames.clear()
            continue

        for filename in filenames:
            full_path = os.path.join(dirpath, filename)
            file_ext = os.path.splitext(filename)[1].lower().strip()

            if file_ext in media_extensions:
                # Remove text within parentheses from the filename
                cleaned_filename = re.sub(r'\s*\(.*?\)\s*', '', filename)

                file_size_mb = round(os.path.getsize(full_path) / (1024 * 1024), 3)
                file_creation_date = datetime.fromtimestamp(os.path.getctime(full_path)).strftime('%Y-%m-%d %H:%M:%S')
                category = media_type  # Use the passed media type as the category

                media_record = (
                    full_path,
                    cleaned_filename,
                    file_ext,
                    file_size_mb,
                    file_creation_date,
                    category,
                    device_name,
                    start_path,
                    master_record_type  # Include the master record type in the tuple
                )
                media_records.append(media_record)

        # Add the media records of the current directory to the overall list
        all_media_records.extend(media_records)

        # Print the tuples after processing each folder
        if media_records:
            print(f"Printing Tuples for folder: {dirpath}")
            for record in media_records:
                print(record)

    # Insert all collected media records into the database
    if all_media_records:
        insert_records(all_media_records)

    end_time = time.time()
    time_taken = end_time - start_time
    print(f"Traversal complete. Time taken: {time_taken:.2f} seconds")
    print(f"Media records: {len(all_media_records)} found")    



# Example usage
directory = '/path/to/media/files'
media_files = traverse_folders(directory)
for media_file in media_files:
    print(media_file)