@echo off
chcp 65001 >nul
title MelodyFlow Studio
setlocal enabledelayedexpansion

rem ============================================================
rem  MelodyFlow Studio - lanzador para Windows
rem  Arranca el API de ACE-Step (7861) y la web (7862)
rem ============================================================

rem --- RUTA DE ACE-STEP: por defecto en la carpeta Descargas del usuario ---
rem    Modifica esta linea si instalaste ACE-Step en otra ubicación.
set "ACESTEP_DIR=%USERPROFILE%\Downloads\ACE-Step"

rem --- Ruta de esta interfaz web (la carpeta donde este .bat) ---
set "WEB_DIR=%~dp0"
rem    Quitar barra final si existe, para evitar rutas dobles
if "%WEB_DIR:~-1%"=="\" set "WEB_DIR=%WEB_DIR:~0,-1%"

rem --- Variables anti-OOM para GPU tier2 (5.6 GB): INT8 + offload del DiT ---
set "ACESTEP_QUANTIZATION=int8_weight_only"
set "ACESTEP_OFFLOAD_DIT_TO_CPU=true"
set "ACESTEP_OFFLOAD_TO_CPU=true"

rem --- Crea el acceso directo del escritorio si no existe (icono incluido) ---
if not exist "%USERPROFILE%\Desktop\MelodyFlow Studio.lnk" (
    echo  [1/5] Creando acceso directo en el escritorio...
    if exist "%WEB_DIR%icon.ico" (
        powershell -NoProfile -Command ^
            " $s = New-Object -ComObject WScript.Shell; ^
              $sc = $s.CreateShortcut('%USERPROFILE%\Desktop\MelodyFlow Studio.lnk'); ^
              $sc.TargetPath = '%WEB_DIR%start_melodyflow.bat'; ^
              $sc.WorkingDirectory = '%WEB_DIR%'; ^
              $sc.IconLocation = '%WEB_DIR%icon.ico,0'; ^
              $sc.Description = 'Generacion de musica con IA (ACE-Step)'; ^
              $sc.Save()"
    )
)

echo.
echo  ========================================
echo   MelodyFlow Studio
echo   Generacion de musica con IA local
echo  ========================================
echo.

rem --- Verifica Python ---
python --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Python no esta instalado o no esta en el PATH.
    echo  Descargalo en https://www.python.org/downloads/ ^(marca "Add to PATH" al instalar^)
    pause
    exit /b 1
)

rem --- Verifica uv ---
where uv >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] No se encontro "uv" (el gestor de entornos de ACE-Step).
    echo  Instalalo con:  pip install uv
    echo  o descargalo en https://docs.astral.sh/uv/
    pause
    exit /b 1
)

rem --- Verifica que existe la carpeta de ACE-Step ---
if not exist "%ACESTEP_DIR%\" (
    echo  [ERROR] No se encuentra la carpeta de ACE-Step: %ACESTEP_DIR%
    echo  Edita este archivo (.bat) y corrige la linea "set ACESTEP_DIR=..."
    pause
    exit /b 1
)

rem --- Arranca la API de ACE-Step (puerto 7861) si no esta en marcha ---
curl -s -m 3 http://127.0.0.1:7861/health >nul 2>&1
if errorlevel 1 (
    echo  [2/5] Arrancando API de ACE-Step en el puerto 7861...
    rem Definir variables de entorno anti-OOM que el servidor ACE-Step leyede GetEnv
    set "ACESTEP_QUANTIZATION=int8_weight_only"
    set "ACESTEP_OFFLOAD_DIT_TO_CPU=true"
    set "ACESTEP_OFFLOAD_TO_CPU=true"
    start "ACE-Step API" /b cmd /k "cd /d %ACESTEP_DIR% && uv run --no-sync acestep-api --host 127.0.0.1 --port 7861"
) else (
    echo  [2/5] La API de ACE-Step ya esta corriendo.
)

rem --- Espera a que el API responda (hasta 5 minutos) ---
echo  [3/5] Esperando a que el servidor este listo (max 5 min)...
set /a count=0
:waitloop
curl -s -m 3 http://127.0.0.1:7861/health >nul 2>&1
if not errorlevel 1 goto api_ready
set /a count+=1
if %count% GEQ 60 (
    echo  [AVISO] El servidor no respondio en 5 minutos.
    echo  Revisa la ventana "ACE-Step API" por si muestra un error.
    goto serve_web
)
timeout /t 5 /nobreak >nul
goto waitloop

:api_ready
echo  [OK] API de ACE-Step lista.

:serve_web
rem --- Sirve la web (puerto 7862) si no esta en marcha ---
curl -s -m 3 http://127.0.0.1:7862/index.html >nul 2>&1
if errorlevel 1 (
    echo  [4/5] Sirviendo la web en http://127.0.0.1:7862 ...
    rem    Usar cd para asegurar el directorio correcto (quitar barra final si la hay)
    set "WEB_SANE=%WEB_DIR%"
    if "%WEB_SANE:~-1%"=="\" set "WEB_SANE=%WEB_SANE:~0,-1%"
    start "MelodyFlow Web" cmd /c "python -m http.server 7862 --bind 127.0.0.1 --directory "%WEB_SANE%""
) else (
    echo  [4/5] La web ya esta corriendo.
)

rem --- Abre el navegador ---
timeout /t 2 /nobreak >nul
echo.
echo  Abriendo MelodyFlow Studio en tu navegador...
start "" "http://127.0.0.1:7862/index.html"

echo.
echo  Todo listo. Puedes cerrar esta ventana; la API y la web siguen corriendo.
echo  Para detenerlas, cierra las ventanas "ACE-Step API" y "MelodyFlow Web".
pause
endlocal