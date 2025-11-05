import pytest
import logging
from unittest.mock import patch, MagicMock
from main import main

class TestMainFunction:
    @patch('main.logging')
    def test_logging_configuration_enabled(self, mock_logging):
        # Mock the logging.basicConfig to test its configuration
        mock_logging.basicConfig = MagicMock()
        
        # Set enable_logging to True
        with patch('main.enable_logging', True):
            main()
        
        # Assert that logging.basicConfig was called with the correct parameters
        mock_logging.basicConfig.assert_called_with(
            filename='D:\\PythonMusic\\pythonProject6\\music-new\\application.log',
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s'
        )

    @patch('main.logging')
    def test_logging_configuration_disabled(self, mock_logging):
        # Mock the logging.basicConfig to test its configuration
        mock_logging.basicConfig = MagicMock()
        
        # Set enable_logging to False
        with patch('main.enable_logging', False):
            main()
        
        # Assert that logging.basicConfig was called with the correct parameters
        mock_logging.basicConfig.assert_called_with(level=logging.CRITICAL)

    @patch('main.logging')
    @patch('main.getWindow', side_effect=Exception("Test Exception"))
    def test_exception_handling_and_logging(self, mock_get_window, mock_logging):
        # Mock sys.exit to prevent the test from exiting
        with patch('sys.exit') as mock_exit:
            main()
        
        # Assert that logging.error was called with the exception message
        mock_logging.error.assert_called_with("An error occurred: %s", "Test Exception")
        
        # Assert that sys.exit was called with 1
        mock_exit.assert_called_with(1)