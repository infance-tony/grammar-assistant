; Grammar Assistant Windows Installer Script
; Built with Inno Setup 6.x
; Bundles: Flutter UI + Embedded Python Backend + GGUF Model

#define AppName "Grammar Assistant"
#define AppVersion "1.0.0"
#define AppPublisher "Grammar Assistant"
#define AppExeName "grammar_assistant.exe"
#define AppId "{{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
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
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; Estimated disk space (Flutter ~25MB + Python ~140MB + Model ~380MB)
ExtraDiskSpaceRequired=572522496

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Flutter Windows app (release build)
Source: "..\..\frontend\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Embedded Python AI backend (python.exe + site-packages + backend source)
Source: "..\..\backend\dist\grammar_backend_python\*"; DestDir: "{app}\grammar_backend_python"; Flags: ignoreversion recursesubdirs createallsubdirs

; AI Model (GGUF file — ~380MB)
Source: "..\..\backend\models\qwen.gguf"; DestDir: "{app}\models"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "Launch Grammar Assistant"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\grammar_backend_python"
Type: filesandordirs; Name: "{app}\models"
Type: dirifempty; Name: "{app}"
