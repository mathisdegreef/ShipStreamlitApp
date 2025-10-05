@echo off
setlocal enableextensions

echo ==========================================
echo [INFO] Starting Streamlit App
echo ==========================================

REM --- Move to script directory ---
cd /d "%~dp0"
echo [INFO] Working directory: %CD%

REM --- Virtual environment folder ---
set VENV_DIR=.venv

REM --- Locate Python ---
where py >nul 2>nul
if %errorlevel%==0 (
  set PY=py -3.11
  echo [INFO] Found Python launcher: using "py -3.11"
) else (
  where python >nul 2>nul
  if %errorlevel%==0 (
    set PY=python
    echo [INFO] Found python on PATH: using "python"
  ) else (
    echo [ERROR] Python not found. Please install Python 3.11 from https://www.python.org/downloads/windows/
    pause
    exit /b 1
  )
)

REM --- Create venv if missing ---
if not exist "%VENV_DIR%\Scripts\python.exe" (
  echo [INFO] Creating new virtual environment in "%VENV_DIR%"...
  %PY% -m venv "%VENV_DIR%"
) else (
  echo [INFO] Virtual environment already exists.
)

REM --- Check if Streamlit is installed inside the venv ---
call "%VENV_DIR%\Scripts\python.exe" -m pip show streamlit >nul 2>&1
if %errorlevel%==0 (
  echo [INFO] Streamlit already installed. Skipping dependency installation.
) else (
  echo [INFO] Installing required packages from requirements.txt...
  call "%VENV_DIR%\Scripts\python.exe" -m pip install --upgrade pip wheel
  call "%VENV_DIR%\Scripts\python.exe" -m pip install -r requirements.txt
)

REM --- Start Streamlit in background ---
echo [INFO] Launching Streamlit app...
start "" /min cmd /c ""%VENV_DIR%\Scripts\python.exe" -m streamlit run app.py --server.headless=true"

REM --- Wait until the port is open before launching browser ---
set PORT=8501
echo [INFO] Waiting for http://localhost:%PORT% to become available...

powershell -NoProfile -Command ^
  "$port=%PORT%; for ($i=0; $i -lt 120; $i++) { if ((Test-NetConnection -ComputerName 'localhost' -Port $port).TcpTestSucceeded) { exit 0 } Start-Sleep -Milliseconds 500 }; exit 1"

if %errorlevel%==0 (
  echo [INFO] Server is up! Opening browser...
  start "" http://localhost:%PORT%
) else (
  echo [WARN] Timed out waiting for the Streamlit server to start.
)

echo [INFO] Done.
endlocal
