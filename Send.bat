@echo off
setlocal

REM Exemplo de chamada via CMD/Batch
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "PowMailSender.ps1" -ID "Rlt_Diario"

endlocal
