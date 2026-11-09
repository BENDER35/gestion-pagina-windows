# Didactic guide: building a Windows installer from Ubuntu

## 1. Goal

This guide explains how to package `GestionPagina.ps1` into a Windows
`.exe` installer generated from Ubuntu, and how the installer included
in this repository was built.

The resulting installer:

- Copies the script and documentation to `C:\Program Files\GestionPagina`.
- Creates Start Menu and Desktop shortcuts.
- Creates an uninstaller.
- Requests administrator privileges through UAC.
- Can launch the manager when installation finishes.

## 2. Options for creating a self-installing EXE

| Option | Advantages | Drawbacks | From Ubuntu? |
|---|---|---|---|
| **NSIS** (recommended) | Real installer, uninstaller, shortcuts, UAC, multilingual | Requires learning its scripting language | Yes, with `makensis` |
| **7-Zip SFX** | Very simple; creates a self-extracting EXE | No uninstaller or shortcuts; less professional | Yes, with the 7-Zip SFX module |
| **C# / .NET wrapper** | Single portable EXE; can embed the `.ps1` | Not a real installer; no shortcuts | Yes, with `dotnet publish -r win-x64` |
| **PS2EXE** | Converts the `.ps1` directly into an `.exe` | Requires Windows and the `ps2exe` module; antivirus may flag it | Not reliably |
| **IExpress** | Built into Windows; creates a self-extracting package | Windows-only; limited configuration | No |
| **Inno Setup + Wine** | Very complete and visual installer | Heavier; depends on Wine | Yes, with Wine |

This project uses **NSIS** because it creates a professional installer
with an uninstaller, shortcuts and UAC elevation, and it can be compiled
from Ubuntu without a Windows machine.

## 3. Project structure

```text
.
├── GestionPagina.ps1              # Main script
├── GestionPagina.cmd              # Windows launcher
├── Tutorial_Ejecucion.txt         # Spanish tutorial
├── Tutorial_Execution_EN.txt      # English tutorial
├── Guia_Autoinstalador_ES.md      # Spanish guide
├── Installer_Guide_EN.md          # This guide
├── README.md                      # Repository overview
├── LICENSE                        # MIT license
├── installer/
│   └── GestionPagina.nsi          # NSIS script
└── dist/
    └── GestionPagina_Setup_1.0.0.exe
```

## 4. Requirements on Ubuntu

### Option A: install NSIS with administrator permissions

```bash
sudo apt update
sudo apt install nsis
makensis -VERSION
```

### Option B: install NSIS locally without `sudo`

If you do not have administrator permissions, download the `.deb`
packages and extract them into a local folder:

```bash
mkdir -p /tmp/nsis-local
cd /tmp/nsis-local
apt-get download nsis nsis-common
mkdir -p root
dpkg-deb -x nsis-common_*.deb root
dpkg-deb -x nsis_*.deb root
```

Check that it works:

```bash
NSISDIR=/tmp/nsis-local/root/usr/share/nsis \
  /tmp/nsis-local/root/usr/bin/makensis -VERSION
```

## 5. How the NSIS installer works

The `installer/GestionPagina.nsi` file defines:

- **Application name and version**.
- **Install directory**: `$PROGRAMFILES64\GestionPagina`.
- **`RequestExecutionLevel admin`**: the installer requests UAC on start.
- **Files it copies**: script, launcher, tutorials, guides and license.
- **Shortcuts** in the Start Menu and on the Desktop.
- **Uninstaller** (`Uninstall.exe`) and an entry in “Installed apps”.
- **Finish page** with the option to launch the manager.

The `GestionPagina.cmd` launcher runs:

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GestionPagina.ps1"
```

`GestionPagina.ps1` checks whether it has administrator permissions. If
it does not, it relaunches itself with `Start-Process -Verb RunAs`, which
shows the UAC prompt. This works both from the installer and from the
Start Menu shortcut.

## 6. Building the installer

From the `installer` folder:

```bash
cd installer
makensis GestionPagina.nsi
```

If you used the local NSIS installation:

```bash
cd installer
NSISDIR=/tmp/nsis-local/root/usr/share/nsis \
  /tmp/nsis-local/root/usr/bin/makensis GestionPagina.nsi
```

The result is written to `dist/GestionPagina_Setup_1.0.0.exe`.

## 7. Testing the installer on Windows

1. Download `GestionPagina_Setup_1.0.0.exe`.
2. Double-click it.
3. Accept the UAC prompt.
4. Choose the installation folder (default: `C:\Program Files\GestionPagina`).
5. Click “Install”.
6. When finished, you can check “Run the Page File Manager now”.
7. You can also open it from the Start Menu or the Desktop.

## 8. Uninstalling

- Open **Settings → Apps → Installed apps**.
- Find **Gestor de Paginación Windows**.
- Click **Uninstall**.

You can also run `Uninstall.exe` from the installation folder. The
uninstaller removes files, shortcuts and registry entries. It **does not
revert** page file changes; if you want to restore the previous page file
configuration, use option `[I]` in the script before uninstalling.

## 9. Security and SmartScreen

The EXE is not digitally signed, so Windows SmartScreen may show a
warning. To continue:

1. Click **More info**.
2. Click **Run anyway**.

For professional distribution, consider signing the installer with a
code-signing certificate (SignPath, Certum, Sectigo, etc.). Signing
avoids most SmartScreen and antivirus warnings.

You can also publish the SHA-256 hash next to the EXE so users can verify
its integrity:

```bash
sha256sum dist/GestionPagina_Setup_1.0.0.exe
```

## 10. Customization

In `installer/GestionPagina.nsi` you can change:

- `APP_NAME`: visible name.
- `APP_VERSION`: version.
- `APP_PUBLISHER`: author.
- `InstallDir`: installation folder.
- `OutFile`: name and path of the generated EXE.
- The `MUI_ICON` and `MUI_UNICON` icons.
- The installer languages (`MUI_LANGUAGE`).

## 11. Quick alternatives

### 7-Zip SFX

Creates a self-extracting archive that runs a launcher. It is simpler,
but it does not create an uninstaller or shortcuts.

### C# / .NET wrapper

You can create a portable EXE that embeds the `.ps1` as a resource and
runs PowerShell with elevation:

```bash
dotnet new console -n Launcher
# Add the .ps1 as EmbeddedResource and build:
dotnet publish -c Release -r win-x64 --self-contained true
```

### PS2EXE

On Windows:

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-ps2exe .\GestionPagina.ps1 .\GestionPagina.exe
```

### IExpress

On Windows: run `iexpress.exe`, select the `.ps1` file and a `.cmd`
launcher, and generate the self-extracting package.

## 12. Troubleshooting

- **“Cannot load the file because running scripts is disabled”**: run the
  script with `-ExecutionPolicy Bypass` or use the `.cmd` launcher.
- **UAC cancelled**: the script will not run; try again and accept the
  prompt.
- **Antivirus flags the EXE**: common with unsigned NSIS installers. Add
  an exclusion or sign the binary.
- **32-bit Windows**: `$PROGRAMFILES64` does not exist. Change
  `InstallDir` to `$PROGRAMFILES\GestionPagina`.
- **Paths with spaces**: the launcher uses `%~dp0` and quotes to support
  paths such as `C:\Program Files\...`.

## 13. Release packaging

For a release, it is recommended to attach:

- `GestionPagina_Setup_1.0.0.exe` (installer).
- `GestionPagina_v1.0.0.zip` (source code and documentation).
- A `SHA256SUMS.txt` file with the hashes.

This way, users can download the installer or the source code, verify
integrity and build it themselves.
