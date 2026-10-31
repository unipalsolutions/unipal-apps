; Windows installer for the UniPal desktop app (Inno Setup 6).
; Built by .github/workflows/desktop.yml: iscc /DAppVersion=x.y.z /DSourceDir=<release folder> unipal.iss
; Installs per user (no admin rights), so staff can install it themselves.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\installer"
#endif

[Setup]
; Never change AppId: Windows uses it to upgrade and uninstall earlier versions.
AppId={{6B1E5C2A-3F4D-4C8E-9A57-2D1B8E0F7C31}
AppName=UniPal
AppVersion={#AppVersion}
AppPublisher=UniPal Group
AppPublisherURL=https://unipal.group
DefaultDirName={localappdata}\Programs\UniPal
DefaultGroupName=UniPal
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=UniPal-Setup-{#AppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\unipal.exe
UninstallDisplayName=UniPal
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\UniPal"; Filename: "{app}\unipal.exe"
Name: "{autodesktop}\UniPal"; Filename: "{app}\unipal.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\unipal.exe"; Description: "{cm:LaunchProgram,UniPal}"; Flags: nowait postinstall skipifsilent
