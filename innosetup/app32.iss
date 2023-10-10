[Setup]
AppName=Torva Launcher
AppPublisher=Torva
UninstallDisplayName=Torva
AppVersion=${project.version}
AppSupportURL=https://torva.io/
DefaultDirName={localappdata}\Torva

; ~30 mb for the repo the launcher downloads
ExtraDiskSpaceRequired=30000000
ArchitecturesAllowed=x86 x64
PrivilegesRequired=lowest

WizardSmallImageFile=${basedir}/app_small.bmp
WizardImageFile=${basedir}/left.bmp
SetupIconFile=${basedir}/app.ico
UninstallDisplayIcon={app}\Torva.exe

Compression=lzma2
SolidCompression=yes

OutputDir=${basedir}
OutputBaseFilename=TorvaSetup32

[Tasks]
Name: DesktopIcon; Description: "Create a &desktop icon";

[Files]
Source: "${basedir}\build\win-x86\Torva.exe"; DestDir: "{app}"
Source: "${basedir}\build\win-x86\Torva.jar"; DestDir: "{app}"
Source: "${basedir}\build\win-x86\launcher_x86.dll"; DestDir: "{app}"
Source: "${basedir}\build\win-x86\config.json"; DestDir: "{app}"
Source: "${basedir}\build\win-x86\jre\*"; DestDir: "{app}\jre"; Flags: recursesubdirs
Source: "${basedir}\app.ico"; DestDir: "{app}"
Source: "${basedir}\left.bmp"; DestDir: "{app}"
Source: "${basedir}\app_small.bmp"; DestDir: "{app}"

[Icons]
; start menu
Name: "{userprograms}\Torva\Torva"; Filename: "{app}\Torva.exe"
Name: "{userprograms}\Torva\Torva (configure)"; Filename: "{app}\Torva.exe"; Parameters: "--configure"
Name: "{userprograms}\Torva\Torva (safe mode)"; Filename: "{app}\Torva.exe"; Parameters: "--safe-mode"
Name: "{userdesktop}\Torva"; Filename: "{app}\Torva.exe"; Tasks: DesktopIcon

[Run]
Filename: "{app}\Torva.exe"; Parameters: "--postinstall"; Flags: nowait
Filename: "{app}\Torva.exe"; Description: "&Open Torva"; Flags: postinstall skipifsilent nowait

[InstallDelete]
; Delete the old jvm so it doesn't try to load old stuff with the new vm and crash
Type: filesandordirs; Name: "{app}\jre"
; previous shortcut
Type: files; Name: "{userprograms}\Torva.lnk"

[UninstallDelete]
Type: filesandordirs; Name: "{%USERPROFILE}\.torva\repository2"
; includes install_id, settings, etc
Type: filesandordirs; Name: "{app}"

[Code]
#include "upgrade.pas"