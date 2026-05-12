# -*- mode: python ; coding: utf-8 -*-
# MediaVerse PyInstaller spec file

import os
from pathlib import Path

block_cipher = None
project_root = os.path.abspath('.')

# ── Data files to bundle ──────────────────────────────────────────────

datas = []

# QML files
for f in Path(project_root, 'Sandbox', 'MediaPlayerQML').glob('*.qml'):
    datas.append((str(f), 'Sandbox/MediaPlayerQML'))

# Python source files (imported at runtime via sys.path, not compiled in)
for f in Path(project_root, 'Sandbox', 'MediaPlayerPy').glob('*.py'):
    datas.append((str(f), 'Sandbox/MediaPlayerPy'))

# Playback module
for f in Path(project_root, 'Sandbox', 'Playback').glob('*.py'):
    datas.append((str(f), 'Sandbox/Playback'))

# DB utilities
for f in Path(project_root, 'dbMySql').glob('*.py'):
    datas.append((str(f), 'dbMySql'))
for f in Path(project_root, 'dbMySql').glob('*.sql'):
    datas.append((str(f), 'dbMySql'))

# project_paths.py at root level
datas.append((os.path.join(project_root, 'project_paths.py'), '.'))

# Assets — config JSON files
for name in [
    'Config.json', 'MainMenu.json', 'Splash.json', 'XMLCategories.json',
    'Category.json', 'mediaverse.ico', 'Collections.jpg', 'Collections.png',
    'MediaVerse 1.jpg', 'mediaverse2.jpg',
]:
    p = os.path.join(project_root, 'Assets', name)
    if os.path.exists(p):
        datas.append((p, 'Assets'))

# Assets — starter data files (empty/minimal versions for fresh install)
for name in [
    'xml_collection_data.json', 'xml_collection_data_b.json',
    'tv_watch_progress.json', 'manifest_build_log.json',
]:
    p = os.path.join(project_root, 'Assets', name)
    if os.path.exists(p):
        datas.append((p, 'Assets'))

# Assets/Splash images
splash_dir = os.path.join(project_root, 'Assets', 'Splash')
if os.path.isdir(splash_dir):
    for f in Path(splash_dir).iterdir():
        if f.is_file():
            datas.append((str(f), 'Assets/Splash'))

# Fonts
font_dir = os.path.join(project_root, 'Fonts', 'fontawesome-free-7.1.0-desktop')
if os.path.isdir(font_dir):
    for root, dirs, files in os.walk(font_dir):
        for f in files:
            src = os.path.join(root, f)
            rel = os.path.relpath(root, project_root)
            datas.append((src, rel))

# Desktop shortcut icon
datas.append((os.path.join(project_root, 'images', 'icon_100.ico'), 'images'))

# images/ folder (UI assets)
images_dir = os.path.join(project_root, 'images')
if os.path.isdir(images_dir):
    for f in Path(images_dir).iterdir():
        if f.is_file():
            datas.append((str(f), 'images'))

# sqlCreds.env template
datas.append((os.path.join(project_root, 'sqlCreds.env'), '.'))


# ── Hidden imports ────────────────────────────────────────────────────

hiddenimports = [
    # PySide6 core
    'PySide6.QtCore',
    'PySide6.QtGui',
    'PySide6.QtWidgets',
    'PySide6.QtQml',
    'PySide6.QtQuick',
    'PySide6.QtMultimedia',
    # Qt5Compat (used in QML)
    'PySide6.Qt5Compat',
    # Database
    'mysql.connector',
    'mysql.connector.plugins',
    'mysql.connector.plugins.caching_sha2_password',
    'mysql.connector.plugins.mysql_native_password',
    # Google AI
    'google.generativeai',
    'google.auth',
    # Network / HTTP
    'requests',
    'urllib3',
    # Media control
    'pymcws',
    # Image processing
    'PIL',
    'PIL.Image',
    'PIL.ImageDraw',
    'PIL.ImageFont',
    # System
    'psutil',
    'dotenv',
    'win32api',
    'win32con',
    'win32gui',
    'wmi',
    'pythoncom',
    # Standard library sometimes missed
    'json',
    'threading',
    'subprocess',
    'ctypes',
    'ctypes.wintypes',
    'logging',
    'xml.etree.ElementTree',
]


# ── Analysis ──────────────────────────────────────────────────────────

a = Analysis(
    [os.path.join(project_root, 'MediaVerse.py')],
    pathex=[
        project_root,
        os.path.join(project_root, 'Sandbox', 'MediaPlayerPy'),
        os.path.join(project_root, 'Sandbox'),
        os.path.join(project_root, 'Sandbox', 'Playback'),
    ],
    binaries=[],
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'matplotlib', 'numpy', 'scipy', 'pandas',
        'tkinter', 'unittest', 'test',
    ],
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='MediaVerse',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,          # windowed — no console
    disable_windowed_traceback=False,
    icon=os.path.join(project_root, 'Assets', 'mediaverse.ico'),
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name='MediaVerse',
)
