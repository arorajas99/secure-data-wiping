@echo off
echo Building CleanSlate...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Python is not installed or not in PATH
    exit /b 1
)

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

REM Create directories if they don't exist
if not exist "logs" mkdir logs
if not exist "certificates" mkdir certificates

REM Build executable with PyInstaller
echo.
echo Building executable...
pyinstaller --onefile --windowed ^
    --name="CleanSlate" ^
    --add-data="utils;utils" ^
    --hidden-import=psutil ^
    --hidden-import=tkinter ^
    main.py

echo.
echo Build complete! Executable is in dist/CleanSlate.exe
pause
