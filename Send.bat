@echo off
setlocal

REM Exemplo de chamada via CMD/Batch
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PowMailSender.ps1" -ID "Relatorio_Diario"

endlocal
