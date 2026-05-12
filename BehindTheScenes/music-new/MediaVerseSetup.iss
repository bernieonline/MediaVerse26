; MediaVerse Installer — Inno Setup 6 Script
; Packages the PyInstaller output into a single setup .exe

[Setup]
AppName=MediaVerse
AppVersion=1.1
AppPublisher=MediaVerse
AppPublisherURL=https://mediaverse.local
DefaultDirName={localappdata}\MediaVerse
DefaultGroupName=MediaVerse
OutputDir=Output
OutputBaseFilename=MediaVerseSetup
SetupIconFile=images\icon_100.ico
UninstallDisplayIcon={app}\MediaVerse.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Main executable
Source: "dist\MediaVerse\MediaVerse.exe"; DestDir: "{app}"; Flags: ignoreversion

; _internal folder — all bundled dependencies and data
Source: "dist\MediaVerse\_internal\*"; DestDir: "{app}\_internal"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
; Create empty runtime directories that the app populates on first use
Name: "{app}\_internal\cache\thumbnails"
Name: "{app}\_internal\cache\display"
Name: "{app}\_internal\cacheV2\images\display"
Name: "{app}\_internal\cacheV2\images\thumb"
Name: "{app}\_internal\cacheV2\images\carousel"
Name: "{app}\_internal\manifestV2"

[Icons]
; Desktop shortcut with custom icon
Name: "{autodesktop}\MediaVerse"; Filename: "{app}\MediaVerse.exe"; IconFilename: "{app}\_internal\images\icon_100.ico"; Comment: "Launch MediaVerse"

; Start Menu shortcut
Name: "{group}\MediaVerse"; Filename: "{app}\MediaVerse.exe"; IconFilename: "{app}\_internal\images\icon_100.ico"; Comment: "Launch MediaVerse"
Name: "{group}\Uninstall MediaVerse"; Filename: "{uninstallexe}"

[Run]
; Option to launch after install
Filename: "{app}\MediaVerse.exe"; Description: "Launch MediaVerse"; Flags: nowait postinstall skipifsilent unchecked
