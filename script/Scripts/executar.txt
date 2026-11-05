@echo off
call "%USERPROFILE%\AppData\Local\miniforge3\condabin\conda.bat" activate geopdf

if errorlevel 1 (
    echo Erro ao ativar o ambiente geopdf.
    pause
    exit /b 1
)

python "%~dp0processar_geopdf.py"

pause