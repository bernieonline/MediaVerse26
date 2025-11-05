import unittest
from unittest.mock import patch, MagicMock
from dbMySql.db_utils import insert_record

class TestInsertRecord(unittest.TestCase):
    @patch('dbMySql.db_utils.create_db_connection')
    def test_insert_record_success(self, mock_create_db_connection):
        # Mock the database connection and cursor
        mock_connection = MagicMock()
        mock_cursor = MagicMock()
        mock_create_db_connection.return_value = mock_connection
        mock_connection.cursor.return_value = mock_cursor

        # Sample data to insert
        records = [
            ('/path/to/file1', 'file1', '.txt', 1234, '2023-01-01', 'collection1', 'category1', 'device1', '/location1', '2023-01-01', 'checksum1', 'N'),
            ('/path/to/file2', 'file2', '.jpg', 5678, '2023-01-02', 'collection2', 'category2', 'device2', '/location2', '2023-01-02', 'checksum2', 'Y')
        ]

        # Call the function
        insert_record(records)

        # Assertions
        mock_cursor.executemany.assert_called_once()
        mock_connection.commit.assert_called_once()
        mock_cursor.close.assert_called_once()
        mock_connection.close.assert_called_once()

    @patch('dbMySql.db_utils.create_db_connection')
    def test_insert_record_connection_failure(self, mock_create_db_connection):
        # Simulate a failed database connection
        mock_create_db_connection.return_value = None

        # Sample data to insert
        records = [
            ('/path/to/file1', 'file1', '.txt', 1234, '2023-01-01', 'collection1', 'category1', 'device1', '/location1', '2023-01-01', 'checksum1', 'N')
        ]

        # Call the function
        insert_record(records)

        # Assertions
        mock_create_db_connection.assert_called_once()

if __name__ == '__main__':
    unittest.main()