@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
cd /d "%~dp0"

title Sonicall: AI Music and Cover Studio
color 0E

echo ========================================================
echo   Sonicall: AI Music and Cover Studio (Truncgil Teknoloji)
echo   YuE2 (3B INT8 ConvRot) and SheetSage2 Melody Engine
echo ========================================================
echo.

:: 1. Check Python
where python >nul 2>&1
if %errorlevel% neq 0 goto err_python

:: 2. Check Flutter
where flutter >nul 2>&1
if %errorlevel% neq 0 goto err_flutter

:: 3. Check / Start Python Backend
echo [1/2] Yerel Yapay Zeka Motoru kontrol ediliyor (Port 5824)...

curl.exe -s -m 1 http://127.0.0.1:5824/api/status >nul 2>&1
if %errorlevel% equ 0 goto backend_already_running

echo [1/2] Yapay Zeka Motoru baslatiliyor (FastAPI / Port 5824)...
if exist backend_startup.log del /f /q backend_startup.log >nul 2>&1
start "Sonicall AI Engine" /min cmd /c "python backend/server.py > backend_startup.log 2>&1"

set RETRIES=0
:wait_backend
ping -n 2 127.0.0.1 >nul
curl.exe -s -m 1 http://127.0.0.1:5824/api/status >nul 2>&1
if %errorlevel% equ 0 goto backend_ready

set /a RETRIES+=1
if %RETRIES% lss 15 goto wait_backend

color 0C
echo.
echo ======================================================================
echo [KRITIK HATA] Yapay Zeka Motoru baslatilamadi (Port 5824)!
echo ======================================================================
echo.
echo Backend Cikti Logu: backend_startup.log
echo ----------------------------------------------------------------------
if exist backend_startup.log (
    type backend_startup.log
) else (
    echo [UYARI] backend_startup.log dosyasi olusturulamadi.
)
echo ----------------------------------------------------------------------
echo.
echo Lutfen yukaridaki Python hata kayitlarini kontrol edin.
echo.
pause
exit /b 1

:backend_already_running
echo [OK] Yapay Zeka Motoru zaten calisiyor (Port 5824).
goto launch_flutter

:backend_ready
echo [OK] Yapay Zeka Motoru hazir ve yanit veriyor!
echo.

:launch_flutter
:: 4. Launch Flutter Desktop
echo [2/2] Sonicall Masaustu Studyosu aciliyor...
echo.

flutter run -d windows
set FLUTTER_EXIT_CODE=%errorlevel%

if %FLUTTER_EXIT_CODE% equ 0 goto finish_app

color 0C
echo.
echo ======================================================================
echo [HATA] Sonicall calisirken bir hata olustu! Hata Kodu: %FLUTTER_EXIT_CODE%
echo ======================================================================
echo.
echo Olasi Hata Nedenleri:
echo 1. Visual Studio C++ Desktop Development bilesenleri eksik olabilir.
echo 2. Calisma aninda bir baglanti veya arayuz hatasi gerceklesmis olabilir.
echo 3. Lutfen konsoldaki kirmizi hata mesajlarini inceleyin.
echo.
pause
exit /b %FLUTTER_EXIT_CODE%

:err_python
color 0C
echo [HATA] Python sisteminizde bulunamadi!
echo Lutfen Python 3.10+ yukleyin ve PATH ortam degiskenine ekleyin.
echo.
pause
exit /b 1

:err_flutter
color 0C
echo [HATA] Flutter SDK sisteminizde bulunamadi!
echo Lutfen Flutter SDK kurun ve PATH ortam degiskenine ekleyin.
echo.
pause
exit /b 1

:finish_app
echo.
echo [SONICALL] Uygulama basariyla kapatildi.
pause
