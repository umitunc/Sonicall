@echo off
chcp 65001 >nul
title Sonicall: AI Music & Cover Studio
color 0E

echo ========================================================
echo   Sonicall: AI Music & Cover Studio (Trunçgil Teknoloji)
echo   YuE2 (3B INT8 ConvRot) & SheetSage2 Melody Engine
echo ========================================================
echo.

:: 1. Start Python Backend in background
echo [1/2] Yerel Yapay Zeka Motoru baslatiliyor (FastAPI / Port 5824)...
start "Sonicall AI Engine" /min python backend/server.py

:: 2. Wait for backend to be ready
timeout /t 2 /nobreak >nul

:: 3. Launch Flutter Desktop
echo [2/2] Sonicall Masaustu Stüdyosu aciliyor...
flutter run -d windows

pause
