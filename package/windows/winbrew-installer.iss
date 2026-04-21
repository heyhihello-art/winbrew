#ifndef WinBrewVersion
  #define WinBrewVersion "0.1.0"
#endif

#ifndef PayloadDir
  #error PayloadDir preprocessor define is required.
#endif

#ifndef OutputDir
  #define OutputDir "dist/windows-installer"
#endif

[Setup]
AppId={{A6F8A096-89D9-4F16-8860-58BEA1C27642}
AppName=WinBrew
AppVersion={#WinBrewVersion}
AppPublisher=WinBrew
DefaultDirName={autopf}\WinBrew
DefaultGroupName=WinBrew
OutputDir={#OutputDir}
OutputBaseFilename=WinBrew-{#WinBrewVersion}-Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "{#PayloadDir}\deps\Git-2.49.0-64-bit.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "{#PayloadDir}\deps\rubyinstaller-devkit-3.4.4-2-x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "{#PayloadDir}\deps\python-3.12.10-amd64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "{#PayloadDir}\winbrew\*"; DestDir: "{app}\brew"; Flags: recursesubdirs createallsubdirs

[Run]
Filename: "{tmp}\Git-2.49.0-64-bit.exe"; Parameters: "/VERYSILENT /NORESTART"; Flags: waituntilterminated
Filename: "{tmp}\rubyinstaller-devkit-3.4.4-2-x64.exe"; Parameters: "/verysilent /norestart"; Flags: waituntilterminated
Filename: "{tmp}\python-3.12.10-amd64.exe"; Parameters: "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"; Flags: waituntilterminated

[Registry]
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "WINBREW_BASH_ROOT"; ValueData: "C:\Program Files\Git"; Flags: preservestringtype uninsdeletevalue

[Icons]
Name: "{group}\WinBrew Bash"; Filename: "C:\Program Files\Git\git-bash.exe"
Name: "{group}\WinBrew Repository"; Filename: "{app}\brew"

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    MsgBox('WinBrew and prerequisites were installed. Open a new shell to refresh PATH and environment variables.', mbInformation, MB_OK);
  end;
end;
