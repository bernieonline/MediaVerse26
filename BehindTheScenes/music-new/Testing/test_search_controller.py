import sys
import types
import importlib.util
from pathlib import Path
from unittest.mock import patch
import pytest

# --------- Minimal PySide6 mocks (so we don't need the actual dependency) ---------
class _MockSignal:
    def __init__(self, *args, **kwargs):
        self._subscribers = []

    def connect(self, fn):
        self._subscribers.append(fn)

    def emit(self, *args, **kwargs):
        for fn in list(self._subscribers):
            fn(*args, **kwargs)


def _MockSlot(*args, **kwargs):
    def decorator(func):
        return func
    return decorator


class _MockQObject:
    def __init__(self, *args, **kwargs):
        pass


@pytest.fixture(autouse=True)
def mock_pyside6(monkeypatch):
    # Create fake PySide6 and PySide6.QtCore modules
    pyside6 = types.ModuleType("PySide6")
    qtcore = types.ModuleType("PySide6.QtCore")

    qtcore.Signal = _MockSignal
    qtcore.Slot = _MockSlot
    qtcore.QObject = _MockQObject

    # Insert into sys.modules before importing the module under test
    monkeypatch.setitem(sys.modules, "PySide6", pyside6)
    monkeypatch.setitem(sys.modules, "PySide6.QtCore", qtcore)


@pytest.fixture
def search_controller_module(mock_pyside6):
    # Dynamically load the SearchController module from its path
    module_path = Path(__file__).resolve().parents[2] / "music-new" / "Sandbox" / "MediaPlayerPy" / "search_controller.py"
    spec = importlib.util.spec_from_file_location("search_controller", str(module_path))
    module = importlib.util.module_from_spec(spec)
    assert spec is not None and spec.loader is not None, "Failed to create module spec for search_controller"
    spec.loader.exec_module(module)
    return module


@pytest.fixture
def SearchController(search_controller_module):
    return search_controller_module.SearchController


# ----------------------- Helper to capture signal emissions -----------------------
class ResultsCatcher:
    def __init__(self):
        self.captured = None

    def handler(self, results):
        self.captured = results


# ------------------------------ Sample master data -------------------------------
@pytest.fixture
def sample_master_data():
    return [
        {
            "title": "Movie With Meta",
            "shared": {
                "video": "W:/Collection/SomeFolder/with_meta.m2ts",
                "xml": "W:/Collection/SomeFolder/with_meta_JRSidecar.xml",
            },
            "cache": {
                "display": "W:/cache/images/with_meta.jpg",
            },
        }
    ]


# ------------------------------------ Tests --------------------------------------

def test_emits_empty_list_when_search_path_missing(SearchController, sample_master_data, monkeypatch):
    sc = SearchController()
    sc.master_data = sample_master_data

    catcher = ResultsCatcher()
    sc.resultsUpdated.connect(catcher.handler)

    with patch("os.path.exists", return_value=False):
        sc.perform_search("query")

    assert catcher.captured == [], "Should emit empty list if search path does not exist"


def test_matches_files_by_query_and_extensions_with_limit(SearchController, sample_master_data, monkeypatch):
    sc = SearchController()
    sc.master_data = sample_master_data

    catcher = ResultsCatcher()
    sc.resultsUpdated.connect(catcher.handler)

    fake_files = [
        ("W:/Collection/SomeFolder", [], [f"match_{i}.m2ts" for i in range(25)]),
    ]

    with patch("os.path.exists", return_value=True), \
         patch("os.walk", return_value=fake_files):
        sc.perform_search("match")

    assert catcher.captured is not None
    assert len(catcher.captured) == 20, "Should cap results at 20"
    assert all(item["filePath"].endswith(('.m2ts', '.mp4', '.mkv', '.avi')) for item in catcher.captured)


def test_includes_metadata_when_master_data_matches(SearchController, sample_master_data):
    sc = SearchController()
    sc.master_data = sample_master_data

    catcher = ResultsCatcher()
    sc.resultsUpdated.connect(catcher.handler)

    # Provide a file that should match master_data[0]['shared']['video']
    fake_walk = [
        ("W:/Collection/SomeFolder", [], ["with_meta.m2ts"]),
    ]

    with patch("os.path.exists", return_value=True), \
         patch("os.walk", return_value=fake_walk):
        sc.perform_search("with_meta")

    assert catcher.captured is not None and len(catcher.captured) == 1
    item = catcher.captured[0]
    assert item["hasMetadata"] is True
    assert item["name"] == "Movie With Meta"
    assert item["xmlPath"].endswith("with_meta_JRSidecar.xml")
    assert item["imageFilename"] == "with_meta.jpg"


def test_raw_file_entry_when_no_metadata(SearchController):
    sc = SearchController()
    sc.master_data = []  # no metadata available

    catcher = ResultsCatcher()
    sc.resultsUpdated.connect(catcher.handler)

    fake_walk = [
        ("W:/Collection/NoMeta", [], ["no_meta_video.mp4"]),
    ]

    with patch("os.path.exists", return_value=True), \
         patch("os.walk", return_value=fake_walk):
        sc.perform_search("no_meta")

    assert catcher.captured is not None and len(catcher.captured) == 1
    item = catcher.captured[0]
    assert item["hasMetadata"] is False
    assert item["xmlPath"] == ""
    assert item["imageFilename"] == ""
    assert item["name"] == "no_meta_video.mp4"


def test_paths_are_normalized_to_forward_slashes(SearchController):
    sc = SearchController()
    sc.master_data = []

    catcher = ResultsCatcher()
    sc.resultsUpdated.connect(catcher.handler)

    # Simulate a Windows-style path from os.walk
    fake_walk = [
        ("W:/Collection/Folder", [], ["Some Video.AVI"]),
    ]

    with patch("os.path.exists", return_value=True), \
         patch("os.walk", return_value=fake_walk):
        sc.perform_search("some video")  # case-insensitive

    assert catcher.captured and "/" in catcher.captured[0]["filePath"], "Expected forward slashes in filePath"


def test_empty_query_returns_first_20_items(SearchController):
    sc = SearchController()
    sc.master_data = []

    catcher = ResultsCatcher()
    sc.resultsUpdated.connect(catcher.handler)

    fake_files = [
        ("W:/Collection/Folder", [], [f"video_{i}.mkv" for i in range(30)]),
    ]

    with patch("os.path.exists", return_value=True), \
         patch("os.walk", return_value=fake_files):
        sc.perform_search("")  # empty query matches all

    assert catcher.captured is not None
    assert len(catcher.captured) == 20


def test_ignores_non_video_extensions(SearchController):
    sc = SearchController()
    sc.master_data = []

    catcher = ResultsCatcher()
    sc.resultsUpdated.connect(catcher.handler)

    fake_walk = [
        ("W:/Collection/Folder", [], ["trailer.txt", "info.nfo", "cover.jpg", "movie.m2ts"]),
    ]

    with patch("os.path.exists", return_value=True), \
         patch("os.walk", return_value=fake_walk):
        sc.perform_search("mov")

    assert catcher.captured is not None and len(catcher.captured) == 1
    assert catcher.captured[0]["filePath"].endswith("movie.m2ts")
