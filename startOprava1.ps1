# ==============================================================================
# SCRIPT: Repair-Win11StartMenu.ps1
# DESCRIPTION: Deep repair of Windows 11 Start Menu using explicit AppX re-registration
# AUTHOR: IT-masterHelper
# VERSION: 1.0.0
# ==============================================================================

[CmdletBinding()]
param()

process {
    # 1. Kontrola administrátorských oprávnění
    [bool]$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $IsAdmin) {
        Write-Error "Tento skript vyzaduje opravneni Administratora."
        return
    }

    # 2. Terminace zavislych procesu
    # StartMenuExperienceHost je zodpovedny za UI nabidky Start
    Write-Host "[*] Terminace procesu StartMenuExperienceHost..." -ForegroundColor Cyan
    [System.Object[]]$StartProcesses = Get-Process -Name "StartMenuExperienceHost" -ErrorAction SilentlyContinue
    if ($null -ne $StartProcesses) {
        Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
    }

    # 3. Restart Windows Exploreru pro obnovu Shellu
    Write-Host "[*] Restartovani Explorer.exe..." -ForegroundColor Cyan
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

    # 4. Re-registrace balicku Start Menu (AppX)
    # Cesta k Manifestu je kriticka pro spravnou identifikaci komponenty
    [string]$AppXManifestPath = "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\AppxManifest.xml"

    if (Test-Path -Path $AppXManifestPath) {
        Write-Host "[*] Provadim re-registraci StartMenuExperienceHost..." -ForegroundColor Cyan
        try {
            # Pouziti parametru -DisableDevelopmentMode vynuti preinstalaci z manifestu
            # -Register definuje instalaci stavajiciho balicku
            Add-AppxPackage -Path $AppXManifestPath -DisableDevelopmentMode -Register -ErrorAction Stop
            Write-Host "[+] Re-registrace probehla uspesne." -ForegroundColor Green
        }
        catch {
            Write-Error "Chyba pri re-registraci AppX: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Manifest soubor nebyl nalezen na ceste: $AppXManifestPath"
    }

    # 5. Volitelna oprava Shell Experience Host (pokud problem pretrvava)
    Write-Host "[*] Provadim kontrolu ShellExperienceHost..." -ForegroundColor Cyan
    [string]$ShellManifestPath = "C:\Windows\SystemApps\ShellExperienceHost_cw5n1h2txyewy\AppxManifest.xml"
    if (Test-Path -Path $ShellManifestPath) {
        Add-AppxPackage -Path $ShellManifestPath -DisableDevelopmentMode -Register -ErrorAction SilentlyContinue
    }

    # 6. Spusteni Exploreru zpet
    Write-Host "[*] Spousteni Explorer.exe..." -ForegroundColor Cyan
    Start-Process -FilePath "explorer.exe"
}