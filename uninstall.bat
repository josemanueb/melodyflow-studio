@echo off
rem MelodyFlow Studio - desinstalador (Windows)
rem Detiene servidores, borra backend ACE-Step, uv, caches de modelos,
rem logs y la propia carpeta de la app.
setlocal enabledelayedexpansion

set "APP_DIR=%USERPROFILE%\Desktop\melodyflow-studio-main"
set "ACESTEP_DIR=%USERPROFILE%\Downloads\ACE-Step"
set "HOME_ALT=%USERPROFILE%"

echo === Deteniendo servidores en puertos 7861/7862 ===
for %%P in (7861 7862) do (
  for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%%P ^| findstr LISTENING') do (
    taskkill /F /PID %%a >nul 2>&1 && echo   detenido PID %%a ^(puerto %%P^)
  )
)

echo === Borrando backend ACE-Step ===
if exist "%ACESTEP_DIR%" rd /s /q "%ACESTEP_DIR%"

echo === Borrando uv y sus caches ===
if exist "%HOME_ALT%\.local\bin\uv.exe" del /f /q "%HOME_ALT%\.local\bin\uv.exe"
if exist "%HOME_ALT%\.local\bin\uvx.exe" del /f /q "%HOME_ALT%\.local\bin\uvx.exe"
if exist "%HOME_ALT%\.cache\uv" rd /s /q "%HOME_ALT%\.cache\uv"
if exist "%HOME_ALT%\.local\share\uv" rd /s /q "%HOME_ALT%\.local\share\uv"

echo === Borrando caches de modelos (HuggingFace/Torch) ===
if exist "%HOME_ALT%\.cache\huggingface" rd /s /q "%HOME_ALT%\.cache\huggingface"
if exist "%HOME_ALT%\.cache\torch" rd /s /q "%HOME_ALT%\.cache\torch"

echo === Borrando acceso directo del escritorio ===
if exist "%USERPROFILE%\Desktop\MelodyFlow Studio.lnk" del /f /q "%USERPROFILE%\Desktop\MelodyFlow Studio.lnk"
if exist "%USERPROFILE%\Desktop\MelodyFlow.desktop" del /f /q "%USERPROFILE%\Desktop\MelodyFlow.desktop"

echo === Borrando la carpeta de la app (incluye este script) ===
start "" /b cmd /c "timeout /t 1 /nobreak >nul & rd /s /q ""%APP_DIR%"""

echo Desinstalacion completada. Todo limpio.
exit /b 0