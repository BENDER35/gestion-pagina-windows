# ============================================================
#  GESTOR DE ARCHIVO DE PAGINACIÓN - WINDOWS
# ============================================================

$ErrorActionPreference = 'Stop'

function Show-Menu {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "   GESTOR DE ARCHIVO DE PAGINACIÓN WINDOWS   " -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[A] - Calcular automáticamente según la RAM instalada" -ForegroundColor Green
    Write-Host "[M] - Calcular introduciendo la RAM manualmente (GB)" -ForegroundColor Green
    Write-Host "[I] - Dejar que Windows lo gestione automáticamente"
    Write-Host "[W] - Paginación ideal para Windows 11 con 'salto de requisitos'" -ForegroundColor Yellow
    Write-Host "[B] - Configuración manual (mínimo y máximo)"
    Write-Host "[V] - Ver configuración actual"
    Write-Host "[E] - Salir"
    Write-Host ""
}

# ------------------------------------------------------------
#  FUNCIONES AUXILIARES
# ------------------------------------------------------------

function Get-InstalledRamGB {
    # Devuelve la RAM física instalada (utilizable) en GB.
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    return [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
}

function Get-PageFileRecommendation {
    param(
        [Parameter(Mandatory)][double]$RamGB,
        [ValidateSet('Estandar', 'Win11Bypass')]
        [string]$Perfil = 'Estandar'
    )

    $ramMB = $RamGB * 1024

    if ($Perfil -eq 'Win11Bypass') {
        # Perfil generoso para equipos con Windows 11 instalado
        # saltándose los requisitos oficiales.
        if ($RamGB -le 4) {
            $minMB = [int][math]::Ceiling($ramMB * 1.5)
            $maxMB = [int][math]::Ceiling($ramMB * 3)
            $nota = 'RAM de 4 GB o menos: se amplía la paginación para compensar la falta de memoria física.'
        }
        elseif ($RamGB -le 8) {
            $minMB = [int][math]::Ceiling($ramMB)
            $maxMB = [int][math]::Ceiling($ramMB * 2)
            $nota = 'RAM de 4 a 8 GB: mínimo igual a la RAM y máximo el doble.'
        }
        elseif ($RamGB -le 16) {
            $minMB = [int][math]::Ceiling($ramMB)
            $maxMB = [int][math]::Ceiling($ramMB * 1.5)
            $nota = 'RAM de 8 a 16 GB: configuración generosa y equilibrada.'
        }
        else {
            $minMB = 16384
            $maxMB = 32768
            $nota = 'Más de 16 GB: tamaño fijo generoso (16-32 GB).'
        }
    }
    else {
        # Perfil estándar para la mayoría de equipos.
        if ($RamGB -le 4) {
            $minMB = [int][math]::Ceiling($ramMB * 1.5)
            $maxMB = [int][math]::Ceiling($ramMB * 3)
            $nota = 'RAM de 4 GB o menos: regla clásica 1,5x / 3x.'
        }
        elseif ($RamGB -le 8) {
            $minMB = [int][math]::Ceiling($ramMB)
            $maxMB = [int][math]::Ceiling($ramMB * 2)
            $nota = 'RAM de 4 a 8 GB: mínimo igual a la RAM y máximo el doble.'
        }
        elseif ($RamGB -le 16) {
            $minMB = [int][math]::Ceiling([math]::Max(4096, $ramMB * 0.5))
            $maxMB = [int][math]::Ceiling([math]::Max(8192, $ramMB))
            $nota = 'RAM de 8 a 16 GB: mínimo la mitad de la RAM (mín. 4 GB) y máximo la RAM (mín. 8 GB).'
        }
        elseif ($RamGB -le 32) {
            $minMB = 8192
            $maxMB = [int][math]::Ceiling([math]::Max(16384, $ramMB * 0.5))
            $nota = 'RAM de 16 a 32 GB: mínimo 8 GB y máximo la mitad de la RAM (mín. 16 GB).'
        }
        else {
            $minMB = 8192
            $maxMB = 16384
            $nota = 'Más de 32 GB: 8 GB de mínimo y 16 GB de máximo es suficiente para la mayoría de usos.'
        }
    }

    return [pscustomobject]@{
        RamGB  = $RamGB
        MinMB  = $minMB
        MaxMB  = $maxMB
        Perfil = $Perfil
        Nota   = $nota
    }
}

function Set-PageFileSizes {
    param(
        [Parameter(Mandatory)][int]$MinMB,
        [Parameter(Mandatory)][int]$MaxMB
    )

    if ($MinMB -le 0 -or $MaxMB -le 0) {
        throw 'Los tamaños deben ser números enteros mayores que 0.'
    }
    if ($MinMB -gt $MaxMB) {
        throw 'El tamaño mínimo no puede ser mayor que el tamaño máximo.'
    }

    $systemDrive  = $env:SystemDrive            # Ejemplo: C:
    $driveLetter  = $systemDrive.TrimEnd(':')  # Ejemplo: C
    $pageFileName = "$systemDrive\pagefile.sys"

    # Tamaño ya asignado en el disco del sistema (si existe).
    $currentAllocatedMB = 0
    $usage = Get-CimInstance -ClassName Win32_PageFileUsage |
        Where-Object { $_.Name -eq $pageFileName } |
        Select-Object -First 1
    if ($usage) {
        $currentAllocatedMB = [int]$usage.AllocatedBaseSize
    }

    # Comprobar espacio libre en el disco del sistema, teniendo en
    # cuenta lo que ya ocupa el archivo de paginación actual.
    $additionalMB = [math]::Max(0, $MaxMB - $currentAllocatedMB)
    $freeMB = [math]::Floor((Get-PSDrive -Name $driveLetter).Free / 1MB)
    if ($freeMB -lt $additionalMB) {
        throw "No hay espacio libre suficiente en $systemDrive. Libre: $freeMB MB; se necesitan $additionalMB MB adicionales (máximo configurado: $MaxMB MB)."
    }

    # Avisar si hay otros archivos de paginación en otros discos.
    $otherPageFiles = @(Get-CimInstance -ClassName Win32_PageFileSetting |
        Where-Object { $_.Name -ne $pageFileName })
    if ($otherPageFiles.Count -gt 0) {
        Write-Host 'Aviso: existen otros archivos de paginación configurados:' -ForegroundColor Yellow
        foreach ($op in $otherPageFiles) {
            Write-Host ("  - {0} ({1}-{2} MB)" -f $op.Name, $op.InitialSize, $op.MaximumSize) -ForegroundColor Yellow
        }
        Write-Host 'Este script solo modificará el del disco del sistema.' -ForegroundColor Yellow
    }

    # Desactivar la gestión automática si está activa.
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) {
        Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $false }
    }

    # Buscar el archivo de paginación del disco del sistema.
    $pageFile = Get-CimInstance -ClassName Win32_PageFileSetting |
        Where-Object { $_.Name -eq $pageFileName } |
        Select-Object -First 1

    if ($pageFile) {
        Set-CimInstance -InputObject $pageFile -Property @{
            InitialSize = $MinMB
            MaximumSize = $MaxMB
        }
    }
    else {
        # Si no existe, crearlo (sucede al desactivar la gestión automática).
        New-CimInstance -ClassName Win32_PageFileSetting -Property @{
            Name        = $pageFileName
            InitialSize = $MinMB
            MaximumSize = $MaxMB
        }
    }
}

function Set-AutomaticPageFile {
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    if ($cs.AutomaticManagedPagefile) {
        Write-Host 'Windows ya está gestionando el archivo de paginación automáticamente.' -ForegroundColor Yellow
        return
    }
    Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $true }
}

function Get-Windows11BypassInfo {
    $os    = Get-CimInstance -ClassName Win32_OperatingSystem
    $build = [int]$os.BuildNumber
    $ramGB = Get-InstalledRamGB
    $reasons = @()

    if ($build -lt 22000) {
        return [pscustomobject]@{
            IsWindows11    = $false
            BypassProbable = $false
            Reasons        = @('El sistema no es Windows 11.')
        }
    }

    if ($ramGB -lt 4) {
        $reasons += "RAM inferior a 4 GB ($ramGB GB)"
    }

    try {
        $tpm = Get-CimInstance -Namespace 'root/cimv2/security/microsofttpm' -ClassName Win32_Tpm -ErrorAction Stop |
            Select-Object -First 1
        if (-not $tpm -or $tpm.SpecVersion -notmatch '2\.0') {
            $reasons += 'TPM 2.0 no detectado'
        }
    }
    catch {
        $reasons += 'TPM no detectado o no accesible'
    }

    try {
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
        if (-not $secureBoot) {
            $reasons += 'Arranque seguro (Secure Boot) desactivado'
        }
    }
    catch {
        $reasons += 'Arranque seguro no disponible (posible BIOS/CSM)'
    }

    return [pscustomobject]@{
        IsWindows11    = $true
        BypassProbable = ($reasons.Count -gt 0)
        Reasons        = $reasons
    }
}

function Show-CurrentPageFile {
    $cs    = Get-CimInstance -ClassName Win32_ComputerSystem
    $os    = Get-CimInstance -ClassName Win32_OperatingSystem
    $ramGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)

    Write-Host "`n--- Configuración actual ---" -ForegroundColor Cyan
    Write-Host ("RAM instalada/utilizable : {0} GB" -f $ramGB)
    Write-Host ("Sistema operativo        : {0} (build {1})" -f $os.Caption, $os.BuildNumber)
    Write-Host ("Gestión automática       : {0}" -f $(if ($cs.AutomaticManagedPagefile) { 'Sí' } else { 'No' }))

    $pageFiles = @(Get-CimInstance -ClassName Win32_PageFileSetting)
    if ($pageFiles.Count -eq 0) {
        Write-Host 'Archivos de paginación    : no hay configuración manual (o Windows los gestiona).' -ForegroundColor Yellow
    }
    else {
        foreach ($pf in $pageFiles) {
            Write-Host ("Archivo                  : {0}" -f $pf.Name)
            Write-Host ("  Tamaño mínimo          : {0} MB" -f $pf.InitialSize)
            Write-Host ("  Tamaño máximo          : {0} MB" -f $pf.MaximumSize)
        }
    }

    $usage = @(Get-CimInstance -ClassName Win32_PageFileUsage)
    if ($usage.Count -gt 0) {
        foreach ($u in $usage) {
            Write-Host ("Uso actual               : {0} ({1} MB asignados, {2} MB en uso, pico {3} MB)" -f $u.Name, $u.AllocatedBaseSize, $u.CurrentUsage, $u.PeakUsage)
        }
    }
    Write-Host ''
}

function Request-Reboot {
    Write-Host ''
    $resp = Read-Host '¿Desea reiniciar ahora para aplicar los cambios? (S/N)'
    if ($resp -match '^[SsYy]') {
        Write-Host 'El equipo se reiniciará en 10 segundos. Pulse Ctrl+C para cancelar.' -ForegroundColor Red
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
    else {
        Write-Host 'Los cambios se aplicarán en el próximo reinicio.' -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------
#  COMPROBACIÓN DE PRIVILEGIOS / AUTOELEVACIÓN
# ------------------------------------------------------------

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Solicitando privilegios de administrador...' -ForegroundColor Yellow

    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    try {
        Start-Process -FilePath 'powershell.exe' `
            -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptPath`"") `
            -Verb RunAs
    }
    catch {
        Write-Host 'ERROR: No se pudieron obtener privilegios de administrador.' -ForegroundColor Red
        Write-Host 'Ejecute PowerShell como administrador e inténtelo de nuevo.'
        Pause
    }
    exit
}

# ------------------------------------------------------------
#  BUCLE PRINCIPAL
# ------------------------------------------------------------

while ($true) {
    Show-Menu
    $choice = Read-Host 'Seleccione una opción'

    switch ($choice.ToUpper()) {
        'A' {
            Write-Host "`n--- Cálculo automático según la RAM ---" -ForegroundColor Yellow
            try {
                $ramGB = Get-InstalledRamGB
                $rec   = Get-PageFileRecommendation -RamGB $ramGB -Perfil 'Estandar'

                Write-Host ("RAM detectada : {0} GB" -f $rec.RamGB) -ForegroundColor Cyan
                Write-Host ("Recomendación : mínimo {0} MB / máximo {1} MB" -f $rec.MinMB, $rec.MaxMB) -ForegroundColor Green
                Write-Host ("Motivo        : {0}" -f $rec.Nota)
                Write-Host ''

                $confirm = Read-Host '¿Aplicar esta configuración? (S/N)'
                if ($confirm -match '^[SsYy]') {
                    Set-PageFileSizes -MinMB $rec.MinMB -MaxMB $rec.MaxMB
                    Write-Host "`n[OK] Configuración aplicada. Se requiere reiniciar para que surta efecto." -ForegroundColor Green
                    Request-Reboot
                }
                else {
                    Write-Host 'Operación cancelada.' -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "`n[ERROR] No se pudo calcular o aplicar la configuración." -ForegroundColor Red
                Write-Host $_.Exception.Message
            }
            Pause
        }
        'M' {
            Write-Host "`n--- Cálculo manual según RAM introducida ---" -ForegroundColor Yellow
            try {
                $ramInput = Read-Host 'Introduce la RAM en GB (ej. 8, 16, 32)'
                $ramManual = 0.0
                $ramText = $ramInput -replace ',', '.'
                if (-not [double]::TryParse($ramText, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$ramManual) -or $ramManual -le 0) {
                    throw 'Debe introducir un número mayor que 0 (puede usar decimales, ej. 7.5 o 7,5).'
                }

                Write-Host ''
                Write-Host 'Perfil de cálculo:'
                Write-Host '  [E] Estándar'
                Write-Host '  [W] Windows 11 con salto de requisitos'
                $perfilInput = Read-Host 'Seleccione perfil (E/W)'
                $perfil = if ($perfilInput -match '^[Ww]') { 'Win11Bypass' } else { 'Estandar' }

                $rec = Get-PageFileRecommendation -RamGB $ramManual -Perfil $perfil

                Write-Host ("`nRAM introducida : {0} GB" -f $rec.RamGB) -ForegroundColor Cyan
                Write-Host ("Perfil          : {0}" -f $(if ($rec.Perfil -eq 'Win11Bypass') { 'Windows 11 con salto de requisitos' } else { 'Estándar' })) -ForegroundColor Cyan
                Write-Host ("Recomendación   : mínimo {0} MB / máximo {1} MB" -f $rec.MinMB, $rec.MaxMB) -ForegroundColor Green
                Write-Host ("Motivo          : {0}" -f $rec.Nota)
                Write-Host ''

                $confirm = Read-Host '¿Aplicar esta configuración al equipo actual? (S/N)'
                if ($confirm -match '^[SsYy]') {
                    Set-PageFileSizes -MinMB $rec.MinMB -MaxMB $rec.MaxMB
                    Write-Host "`n[OK] Configuración aplicada. Se requiere reiniciar para que surta efecto." -ForegroundColor Green
                    Request-Reboot
                }
                else {
                    Write-Host 'Operación cancelada.' -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "`n[ERROR] No se pudo realizar el cálculo manual." -ForegroundColor Red
                Write-Host $_.Exception.Message
            }
            Pause
        }
        'I' {
            Write-Host 'Cambiando a gestión automática...' -ForegroundColor Yellow
            try {
                Set-AutomaticPageFile
                Write-Host "`n[OK] ¡Éxito! Windows ahora gestiona el archivo de paginación automáticamente." -ForegroundColor Green
                Request-Reboot
            }
            catch {
                Write-Host "`n[ERROR] No se pudo cambiar a gestión automática." -ForegroundColor Red
                Write-Host $_.Exception.Message
            }
            Pause
        }
        'W' {
            Write-Host "`n--- Paginación para Windows 11 con 'salto de requisitos' ---" -ForegroundColor Yellow
            try {
                $info = Get-Windows11BypassInfo
                if (-not $info.IsWindows11) {
                    Write-Host '[AVISO] Este equipo no parece ser Windows 11.' -ForegroundColor Yellow
                }
                elseif ($info.BypassProbable) {
                    Write-Host '[INFO] Se han detectado posibles requisitos no cumplidos:' -ForegroundColor Yellow
                    foreach ($r in $info.Reasons) {
                        Write-Host ("  - {0}" -f $r) -ForegroundColor Yellow
                    }
                }
                else {
                    Write-Host '[INFO] No se han detectado requisitos incumplidos, pero se aplicará el perfil generoso.' -ForegroundColor Yellow
                }

                $ramGB = Get-InstalledRamGB
                $rec   = Get-PageFileRecommendation -RamGB $ramGB -Perfil 'Win11Bypass'

                Write-Host ("`nRAM detectada : {0} GB" -f $rec.RamGB) -ForegroundColor Cyan
                Write-Host ("Recomendación : mínimo {0} MB / máximo {1} MB" -f $rec.MinMB, $rec.MaxMB) -ForegroundColor Green
                Write-Host ("Motivo        : {0}" -f $rec.Nota)
                Write-Host 'Consejo       : mantén el archivo de paginación en el SSD del sistema y no lo desactives.' -ForegroundColor DarkGray
                Write-Host ''

                $confirm = Read-Host '¿Aplicar esta configuración? (S/N)'
                if ($confirm -match '^[SsYy]') {
                    Set-PageFileSizes -MinMB $rec.MinMB -MaxMB $rec.MaxMB
                    Write-Host "`n[OK] Configuración aplicada. Se requiere reiniciar para que surta efecto." -ForegroundColor Green
                    Request-Reboot
                }
                else {
                    Write-Host 'Operación cancelada.' -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "`n[ERROR] No se pudo aplicar la configuración para Windows 11." -ForegroundColor Red
                Write-Host $_.Exception.Message
            }
            Pause
        }
        'B' {
            Write-Host "`n--- Configuración Manual ---" -ForegroundColor Yellow
            try {
                $min = Read-Host 'Introduzca el tamaño MÍNIMO (MB)'
                $max = Read-Host 'Introduzca el tamaño MÁXIMO (MB)'

                $minInt = 0
                $maxInt = 0
                if (-not [int]::TryParse($min, [ref]$minInt) -or -not [int]::TryParse($max, [ref]$maxInt)) {
                    throw 'Debe introducir números enteros.'
                }

                Set-PageFileSizes -MinMB $minInt -MaxMB $maxInt
                Write-Host "`n[OK] Configuración aplicada correctamente." -ForegroundColor Green
                Request-Reboot
            }
            catch {
                Write-Host "`n[ERROR] Error durante la configuración manual." -ForegroundColor Red
                Write-Host $_.Exception.Message
            }
            Pause
        }
        'V' {
            Show-CurrentPageFile
            Pause
        }
        'E' {
            Write-Host 'Saliendo del programa...' -ForegroundColor Cyan
            exit
        }
        Default {
            Write-Host "Opción '$choice' no válida. Intente de nuevo." -ForegroundColor Red
            Pause
        }
    }
}
