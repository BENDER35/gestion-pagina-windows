# Gestor de Paginación Windows / Windows Page File Manager

[Español](#español) · [English](#english)

---

## Español

Herramienta didáctica en PowerShell para consultar y configurar el
archivo de paginación (`pagefile.sys`) de Windows.

### Características

- Detecta la RAM instalada y calcula un tamaño de paginación recomendado.
- Permite introducir la RAM manualmente para calcular el pagefile.
- Vuelve a la gestión automática de Windows.
- Incluye un perfil generoso para Windows 11 instalado con “salto de
  requisitos”.
- Configuración manual de mínimo y máximo en MB.
- Muestra la configuración y el uso actual.
- Solicita elevación de administrador automáticamente (UAC).
- Incluye instalador `.exe` para Windows, generado desde Ubuntu con NSIS.

### Descarga rápida

1. Descarga `GestionPagina_Setup_1.0.0.exe` desde la sección **Releases**.
2. Ejecútalo y acepta el aviso de UAC.
3. Sigue el asistente. Al terminar puedes abrir el gestor desde el menú
   Inicio o el escritorio.

Si prefieres no instalar nada, ejecuta directamente
`GestionPagina.cmd` o `GestionPagina.ps1` como administrador.

### Uso directo del script

```powershell
# Opción recomendada: usar el lanzador
.\GestionPagina.cmd

# O ejecutar PowerShell como administrador y lanzar el script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\GestionPagina.ps1
```

### Opciones del menú

| Opción | Descripción |
|---|---|
| `[A]` | Calcula automáticamente según la RAM instalada |
| `[M]` | Calcula introduciendo la RAM manualmente (GB) |
| `[I]` | Deja que Windows gestione el pagefile automáticamente |
| `[W]` | Perfil para Windows 11 con “salto de requisitos” |
| `[B]` | Configuración manual (mínimo y máximo en MB) |
| `[V]` | Ver configuración actual |
| `[E]` | Salir |

### Documentación

- `Tutorial_Ejecucion.txt` — tutorial en español.
- `Tutorial_Execution_EN.txt` — tutorial en inglés.
- `Guia_Autoinstalador_ES.md` — guía para crear el instalador desde Ubuntu.
- `Installer_Guide_EN.md` — English installer guide.

### Compilar el instalador

```bash
cd installer
makensis GestionPagina.nsi
```

El resultado se genera en `dist/GestionPagina_Setup_1.0.0.exe`.

### Seguridad

- El instalador no está firmado digitalmente. SmartScreen puede mostrar
  un aviso: pulsa **Más información → Ejecutar de todas formas**.
- El script modifica el archivo de paginación y requiere reiniciar para
  aplicar los cambios.
- Revisa el código antes de ejecutarlo. Es software didáctico y se
  distribuye sin garantías.

### Repositorios

- GitHub (principal): https://github.com/BENDER35/gestion-pagina-windows
- GitLab (copia de seguridad): https://gitlab.com/BENDER_5000/gestion-pagina-windows

El repositorio de GitHub se replica automáticamente en GitLab mediante
GitHub Actions.

### Licencia

MIT. Consulta `LICENSE`.

---

## English

Didactic PowerShell tool to inspect and configure the Windows page file
(`pagefile.sys`).

### Features

- Detects installed RAM and calculates a recommended page file size.
- Lets you enter RAM manually to calculate the page file.
- Restores Windows automatic management.
- Includes a generous profile for Windows 11 installed with
  “requirements bypass”.
- Manual minimum and maximum configuration in MB.
- Shows current configuration and usage.
- Requests administrator elevation automatically (UAC).
- Includes a Windows `.exe` installer built from Ubuntu with NSIS.

### Quick download

1. Download `GestionPagina_Setup_1.0.0.exe` from the **Releases** section.
2. Run it and accept the UAC prompt.
3. Follow the wizard. When finished, you can open the manager from the
   Start Menu or Desktop.

If you prefer not to install anything, run `GestionPagina.cmd` or
`GestionPagina.ps1` directly as administrator.

### Direct script usage

```powershell
# Recommended: use the launcher
.\GestionPagina.cmd

# Or open PowerShell as administrator and run the script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\GestionPagina.ps1
```

### Menu options

| Option | Description |
|---|---|
| `[A]` | Automatic calculation based on installed RAM |
| `[M]` | Manual calculation by entering RAM (GB) |
| `[I]` | Let Windows manage the page file automatically |
| `[W]` | Windows 11 “requirements bypass” profile |
| `[B]` | Manual configuration (minimum and maximum in MB) |
| `[V]` | View current configuration |
| `[E]` | Exit |

### Documentation

- `Tutorial_Ejecucion.txt` — Spanish tutorial.
- `Tutorial_Execution_EN.txt` — English tutorial.
- `Guia_Autoinstalador_ES.md` — guide to build the installer from Ubuntu.
- `Installer_Guide_EN.md` — English installer guide.

### Build the installer

```bash
cd installer
makensis GestionPagina.nsi
```

The result is written to `dist/GestionPagina_Setup_1.0.0.exe`.

### Security

- The installer is not digitally signed. SmartScreen may show a warning:
  click **More info → Run anyway**.
- The script modifies the page file and requires a restart to apply
  changes.
- Review the code before running it. This is didactic software provided
  without warranty.

### Repositories

- GitHub (primary): https://github.com/BENDER35/gestion-pagina-windows
- GitLab (backup): https://gitlab.com/BENDER_5000/gestion-pagina-windows

The GitHub repository is mirrored automatically to GitLab through
GitHub Actions.

### License

MIT. See `LICENSE`.
