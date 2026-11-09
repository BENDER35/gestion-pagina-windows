@echo off
rem Lanzador del Gestor de Paginacion.
rem El propio script de PowerShell solicita elevacion (UAC) si hace falta.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GestionPagina.ps1"
