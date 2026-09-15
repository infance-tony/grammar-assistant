; Grammar Assistant Windows Installer Script
; Built with Inno Setup 6.x
; Bundles: Flutter UI + Embedded Python Backend + GGUF Model

#define AppName "Grammar Assistant"
#define AppVersion "1.1.0"
#define AppPublisher "Grammar Assistant"
#define AppExeName "grammar_assistant.exe"
#define AppId "{{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\{#AppName}
DefaultGroupName={#AppName}
OutputDir=..\..\dist
OutputBaseFilename=GrammarAssistant_Setup_v{#AppVersion}
SetupIconFile=..\..\frontend\assets\icons\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#AppExeName}
DisableProgramGroupPage=yes
; Run as user (no UAC prompt)
PrivilegesRequired=lowest
CloseApplications=yes
CloseApplicationsFilter=grammar_assistant.exe,grammar_backend.exe

; Estimated disk space (~1.1GB model + 200MB app)
ExtraDiskSpaceRequired=1400000000

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: checkedonce

[InstallDelete]
; Clean old incomplete installs before writing new files
Type: filesandordirs; Name: "{app}\data"
Type: files; Name: "{app}\grammar_assistant.exe"
Type: files; Name: "{app}\flutter_windows.dll"

[Files]
; ── Flutter Windows app ──────────────────────────────────────────────────────
; Root files (exe + DLLs)
Source: "..\..\frontend\build\windows\x64\runner\Release\grammar_assistant.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\frontend\build\windows\x64\runner\Release\flutter_windows.dll";  DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\frontend\build\windows\x64\runner\Release\hotkey_manager_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\frontend\build\windows\x64\runner\Release\screen_retriever_plugin.dll";       DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\frontend\build\windows\x64\runner\Release\sqlite3.dll";                       DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\frontend\build\windows\x64\runner\Release\system_tray_plugin.dll";            DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\frontend\build\windows\x64\runner\Release\window_manager_plugin.dll";         DestDir: "{app}"; Flags: ignoreversion

; data\ subfolder (critical — contains app.so, flutter_assets, icudtl.dat)
Source: "..\..\frontend\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; ── Embedded Python AI backend ───────────────────────────────────────────────
Source: "..\..\backend\dist\grammar_backend_python\*"; DestDir: "{app}\grammar_backend_python"; Flags: ignoreversion recursesubdirs createallsubdirs

; ── AI Models ─────────────────────────────────────────────────────────────────
; Download first:  python backend\download_model.py qwen3-1.7b  (~1.1 GB, recommended)
;                  python backend\download_model.py phi4mini     (~2.3 GB, best quality)
Source: "..\..\backend\models\qwen3-1.7b.gguf"; DestDir: "{app}\models"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\..\backend\models\phi4mini.gguf";   DestDir: "{app}\models"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\..\backend\models\qwen15b.gguf";    DestDir: "{app}\models"; Flags: ignoreversion skipifsourcedoesntexist
Source: "..\..\backend\models\qwen.gguf";       DestDir: "{app}\models"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
Name: "{group}\{#AppName}";           Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}";     Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch Grammar Assistant"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\grammar_backend_python"
Type: filesandordirs; Name: "{app}\models"
Type: filesandordirs; Name: "{app}\data"
Type: dirifempty;     Name: "{app}"
