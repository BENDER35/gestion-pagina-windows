; ============================================================
;  Instalador NSIS - Gestor de Paginación Windows
;  Compilable desde Ubuntu con makensis.
; ============================================================

Unicode true
!include "MUI2.nsh"

!define APP_NAME "Gestor de Paginación Windows"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "BENDER35"
!define APP_URL "https://github.com/BENDER35/gestion-pagina-windows"
!define APP_EXE "GestionPagina.cmd"

Name "${APP_NAME}"
OutFile "..\dist\GestionPagina_Setup_${APP_VERSION}.exe"

InstallDir "$PROGRAMFILES\GestionPagina"
InstallDirRegKey HKLM "Software\GestionPagina" "InstallDir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\Tutorial_Ejecucion.txt"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "English"

; ------------------------------------------------------------
;  Instalación
; ------------------------------------------------------------
Section "Instalación" SecMain
    SectionIn RO

    SetOutPath "$INSTDIR"
    File "..\GestionPagina.ps1"
    File "..\GestionPagina.cmd"
    File "..\Tutorial_Ejecucion.txt"
    File "..\Tutorial_Execution_EN.txt"
    File "..\Guia_Autoinstalador_ES.md"
    File "..\Installer_Guide_EN.md"
    File "..\README.md"
    File "..\LICENSE"

    WriteUninstaller "$INSTDIR\Uninstall.exe"

    CreateDirectory "$SMPROGRAMS\GestionPagina"
    CreateShortCut "$SMPROGRAMS\GestionPagina\Gestor de Paginación.lnk" "$INSTDIR\${APP_EXE}"
    CreateShortCut "$SMPROGRAMS\GestionPagina\Desinstalar.lnk" "$INSTDIR\Uninstall.exe"
    CreateShortCut "$DESKTOP\Gestor de Paginación.lnk" "$INSTDIR\${APP_EXE}"

    WriteRegStr HKLM "Software\GestionPagina" "InstallDir" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina" "DisplayName" "${APP_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina" "Publisher" "${APP_PUBLISHER}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina" "DisplayIcon" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina" "UninstallString" '"$INSTDIR\Uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina" "URLInfoAbout" "${APP_URL}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina" "NoRepair" 1
SectionEnd

; ------------------------------------------------------------
;  Desinstalación
; ------------------------------------------------------------
Section "Uninstall"
    Delete "$INSTDIR\GestionPagina.ps1"
    Delete "$INSTDIR\GestionPagina.cmd"
    Delete "$INSTDIR\Tutorial_Ejecucion.txt"
    Delete "$INSTDIR\Tutorial_Execution_EN.txt"
    Delete "$INSTDIR\Guia_Autoinstalador_ES.md"
    Delete "$INSTDIR\Installer_Guide_EN.md"
    Delete "$INSTDIR\README.md"
    Delete "$INSTDIR\LICENSE"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir "$INSTDIR"

    Delete "$SMPROGRAMS\GestionPagina\Gestor de Paginación.lnk"
    Delete "$SMPROGRAMS\GestionPagina\Desinstalar.lnk"
    RMDir "$SMPROGRAMS\GestionPagina"
    Delete "$DESKTOP\Gestor de Paginación.lnk"

    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\GestionPagina"
    DeleteRegKey HKLM "Software\GestionPagina"
SectionEnd
