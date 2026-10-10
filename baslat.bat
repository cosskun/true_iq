@echo off
chcp 65001 > nul
title TrueIQ - Baslatiliyor...
cd /d "%~dp0"

echo ========================================================
echo   🧠 TrueIQ - BASLATILIYOR...
echo ========================================================
echo.

set "PATH=C:\Users\Developer6\.puro\envs\stable\flutter\bin;%USERPROFILE%\.puro\envs\stable\flutter\bin;%PATH%"

set "FLUTTER_BIN=C:\Users\Developer6\.puro\envs\stable\flutter\bin\flutter.bat"

if not exist "%FLUTTER_BIN%" (
    if exist "%USERPROFILE%\.puro\envs\stable\flutter\bin\flutter.bat" (
        set "FLUTTER_BIN=%USERPROFILE%\.puro\envs\stable\flutter\bin\flutter.bat"
    ) else (
        set "FLUTTER_BIN=flutter"
    )
)

echo [1/2] Tarayici aciliyor (http://localhost:8082)...
start "" "http://localhost:8082"

echo [2/2] Flutter Web Sunucusu baslatiliyor...
echo.
echo IPUCU: Uygulamayi yeniden yuklemek icin bu pencerede R tusuna basabilirsiniz.
echo.

call "%FLUTTER_BIN%" run -d web-server --web-port=8082

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [BILGI] Web-server baslatilamadi, dogrudan Chrome ile deneniyor...
    call "%FLUTTER_BIN%" run -d chrome
)

echo.
echo Uygulama kapatildi.
pause
