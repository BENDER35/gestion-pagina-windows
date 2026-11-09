# Guía didáctica: crear un autoinstalador para Windows desde Ubuntu

## 1. Objetivo

Esta guía explica cómo empaquetar `GestionPagina.ps1` en un instalador
`.exe` para Windows, generado desde Ubuntu, y cómo se ha construido el
instalador incluido en este repositorio.

El instalador resultante:

- Copia el script y la documentación en `C:\Program Files\GestionPagina`
  (o `C:\Program Files (x86)\GestionPagina` en Windows de 64 bits, ya que
  el instalador NSIS generado es de 32 bits).
- Crea accesos directos en el menú Inicio y en el escritorio.
- Crea un desinstalador.
- Solicita privilegios de administrador mediante UAC.
- Permite ejecutar el gestor al terminar la instalación.

## 2. Opciones para crear un EXE autoinstalable

| Opción | Ventajas | Inconvenientes | ¿Desde Ubuntu? |
|---|---|---|---|
| **NSIS** (recomendada) | Instalador real, desinstalador, accesos directos, UAC, multilingüe | Requiere aprender su lenguaje de script | Sí, con `makensis` |
| **7-Zip SFX** | Muy sencillo; genera un EXE que se autoextrae | No tiene desinstalador ni accesos directos; menos profesional | Sí, con el módulo SFX de 7-Zip |
| **Wrapper C# / .NET** | Un único EXE portable; puedes embeber el `.ps1` | No es un instalador como tal; no crea accesos directos | Sí, con `dotnet publish -r win-x64` |
| **PS2EXE** | Convierte el `.ps1` en `.exe` directamente | Requiere Windows y el módulo `ps2exe`; el antivirus puede marcarlo | No de forma fiable |
| **IExpress** | Viene incluido en Windows; genera un autoextraíble | Solo Windows; configuración limitada | No |
| **Inno Setup + Wine** | Instalador muy completo y visual | Más pesado; depende de Wine | Sí, con Wine |

Para este proyecto se eligió **NSIS** porque permite crear un instalador
profesional, con desinstalador, accesos directos y elevación UAC, y se
puede compilar desde Ubuntu sin necesidad de una máquina Windows.

## 3. Estructura del proyecto

```text
.
├── GestionPagina.ps1              # Script principal
├── GestionPagina.cmd              # Lanzador para Windows
├── Tutorial_Ejecucion.txt         # Tutorial en español
├── Tutorial_Execution_EN.txt      # Tutorial en inglés
├── Guia_Autoinstalador_ES.md      # Esta guía
├── Installer_Guide_EN.md          # Guía en inglés
├── README.md                      # Presentación del repositorio
├── LICENSE                        # Licencia MIT
├── installer/
│   └── GestionPagina.nsi          # Script de NSIS
└── dist/
    └── GestionPagina_Setup_1.0.0.exe
```

## 4. Requisitos en Ubuntu

### Opción A: instalar NSIS con permisos de administrador

```bash
sudo apt update
sudo apt install nsis
makensis -VERSION
```

### Opción B: instalar NSIS localmente sin `sudo`

Si no tienes permisos de administrador, puedes descargar los paquetes
`.deb` y extraerlos en una carpeta local:

```bash
mkdir -p /tmp/nsis-local
cd /tmp/nsis-local
apt-get download nsis nsis-common
mkdir -p root
dpkg-deb -x nsis-common_*.deb root
dpkg-deb -x nsis_*.deb root
```

Comprueba que funciona:

```bash
NSISDIR=/tmp/nsis-local/root/usr/share/nsis \
  /tmp/nsis-local/root/usr/bin/makensis -VERSION
```

## 5. Cómo funciona el instalador NSIS

El archivo `installer/GestionPagina.nsi` define:

- **Nombre y versión** de la aplicación.
- **Directorio de instalación**: `$PROGRAMFILES64\GestionPagina`.
- **`RequestExecutionLevel admin`**: el instalador pide UAC al arrancar.
- **Archivos que copia**: script, lanzador, tutoriales, guías y licencia.
- **Accesos directos** en el menú Inicio y en el escritorio.
- **Desinstalador** (`Uninstall.exe`) y entrada en “Aplicaciones instaladas”.
- **Página final** con la opción de ejecutar el gestor.

El lanzador `GestionPagina.cmd` ejecuta:

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GestionPagina.ps1"
```

El propio `GestionPagina.ps1` comprueba si tiene permisos de
administrador. Si no los tiene, se relanza a sí mismo con
`Start-Process -Verb RunAs`, que muestra el aviso de UAC. Así funciona
tanto desde el instalador como desde el acceso directo del menú Inicio.

## 6. Compilar el instalador

Desde la carpeta `installer`:

```bash
cd installer
makensis GestionPagina.nsi
```

Si usaste la instalación local de NSIS:

```bash
cd installer
NSISDIR=/tmp/nsis-local/root/usr/share/nsis \
  /tmp/nsis-local/root/usr/bin/makensis GestionPagina.nsi
```

El resultado se genera en `dist/GestionPagina_Setup_1.0.0.exe`.

## 7. Probar el instalador en Windows

1. Descarga `GestionPagina_Setup_1.0.0.exe`.
2. Haz doble clic.
3. Acepta el aviso de UAC.
4. Elige la carpeta de instalación (por defecto `C:\Program Files\GestionPagina`
   o `C:\Program Files (x86)\GestionPagina` en Windows de 64 bits).
5. Pulsa “Instalar”.
6. Al terminar, puedes marcar “Ejecutar el Gestor de Paginación ahora”.
7. También puedes abrirlo desde el menú Inicio o el escritorio.

## 8. Desinstalar

- Abre **Configuración → Aplicaciones → Aplicaciones instaladas**.
- Busca **Gestor de Paginación Windows**.
- Pulsa **Desinstalar**.

También puedes ejecutar `Uninstall.exe` desde la carpeta de instalación.
El desinstalador elimina archivos, accesos directos y entradas del
registro. **No revierte** los cambios del archivo de paginación; si
quieres dejar la paginación como estaba, usa antes la opción `[I]` del
script para volver a la gestión automática.

## 9. Seguridad y SmartScreen

El EXE no está firmado digitalmente, así que Windows SmartScreen puede
mostrar un aviso. Para continuar:

1. Pulsa **Más información**.
2. Pulsa **Ejecutar de todas formas**.

Para distribuir el instalador de forma profesional, considera firmarlo
con un certificado de firma de código (SignPath, Certum, Sectigo, etc.).
La firma evita la mayoría de avisos de SmartScreen y de antivirus.

También puedes publicar el hash SHA-256 junto al EXE para que los
usuarios verifiquen su integridad:

```bash
sha256sum dist/GestionPagina_Setup_1.0.0.exe
```

## 10. Personalización

En `installer/GestionPagina.nsi` puedes cambiar:

- `APP_NAME`: nombre visible.
- `APP_VERSION`: versión.
- `APP_PUBLISHER`: autor.
- `InstallDir`: carpeta de instalación.
- `OutFile`: nombre y ruta del EXE generado.
- Los iconos `MUI_ICON` y `MUI_UNICON`.
- Los idiomas del instalador (`MUI_LANGUAGE`).

## 11. Alternativas rápidas

### 7-Zip SFX

Crea un autoextraíble que ejecuta un lanzador. Es más simple, pero no
crea desinstalador ni accesos directos.

### Wrapper C# / .NET

Puedes crear un EXE portable que embeba el `.ps1` como recurso y ejecute
PowerShell con elevación:

```bash
dotnet new console -n Launcher
# Añade el .ps1 como EmbeddedResource y compila:
dotnet publish -c Release -r win-x64 --self-contained true
```

### PS2EXE

En Windows:

```powershell
Install-Module ps2exe -Scope CurrentUser
Invoke-ps2exe .\GestionPagina.ps1 .\GestionPagina.exe
```

### IExpress

En Windows: ejecuta `iexpress.exe`, selecciona el archivo `.ps1`, un
lanzador `.cmd` y genera el autoextraíble.

## 12. Solución de problemas

- **“No se puede cargar el archivo porque la ejecución de scripts está
  deshabilitada”**: ejecuta el script con `-ExecutionPolicy Bypass` o
  usa el lanzador `.cmd`.
- **UAC cancelado**: el script no se ejecutará; vuelve a intentarlo y
  acepta el aviso.
- **Antivirus marca el EXE**: es habitual en instaladores NSIS sin
  firmar. Añade una exclusión o firma el binario.
- **Windows de 32 bits**: el instalador usa `$PROGRAMFILES`, por lo que
  funciona en 32 y 64 bits. En 64 bits se instala en
  `Program Files (x86)`; si prefieres `Program Files`, cambia
  `InstallDir` a `$PROGRAMFILES64` y compila un instalador de 64 bits.
- **Rutas con espacios**: el lanzador usa `%~dp0` y comillas para
  soportar rutas como `C:\Program Files\...`.

## 13. Empaquetado para la release

Para publicar una release se recomienda adjuntar:

- `GestionPagina_Setup_1.0.0.exe` (instalador).
- `GestionPagina_v1.0.0.zip` (código fuente y documentación).
- Un archivo `SHA256SUMS.txt` con los hashes.

Con esto, cualquier usuario puede descargar el instalador o el código
fuente, verificar la integridad y compilarlo por su cuenta.
