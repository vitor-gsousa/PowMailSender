@echo off
setlocal

REM Exemplo de chamada via CMD/Batch
REM LINT:IGNORE SEC009
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "PowMailSender.ps1" -ID "Rlt_Diario"
IF ERRORLEVEL 1 (
    echo Ocorreu um erro ao executar o script PowerShell.
    exit /b 1
) ELSE (
    echo Script PowerShell executado com sucesso.
    endlocal
    exit /b 0
)
