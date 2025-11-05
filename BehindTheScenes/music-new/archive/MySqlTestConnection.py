import mysql.connector

config = {
    'host': '192.168.1.100',          # MySQL server IP (TrueNAS jail)
    'user': 'root',                   # MySQL username
    'password': 'Ub24MySql!!!',       # MySQL password
    'database': 'mediamanager',       # Database name
    'ssl_ca': 'X:\Python Projects\BehindTheScenes\pythonProject5\music-new\Certificates\ca-cert.pem',  # Path to the CA certificate (Windows-style path)
    'ssl_verify_cert': False,         # Disable certificate verification (optional for self-signed certs)
    'connection_timeout': 30,         # Connection timeout in seconds
    'ssl_disabled': False,            # Set this to True if you want to disable SSL (not recommended)
    # Alternatively, you can use ssl_mode='PREFERRED' to allow self-signed certs
    #'ssl_mode': 'PREFERRED'           # PREFERRED allows using self-signed certs
}

try:
    print("Attempting connection with config:", config)
    connection = mysql.connector.connect(**config)
    print("Connection object created")

    if connection.is_connected():
        print("Connection established successfully!")
    else:
        print("Connection failed without exception.")
except mysql.connector.Error as err:
    print(f"Connection Failed: {err}")
except Exception as e:
    print(f"Unexpected error: {e}")
finally:
    if 'connection' in locals() and connection.is_connected():
        print("Closing connection...")
        connection.close()
        print("Connection closed")
