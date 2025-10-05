@echo off
setlocal enableextensions

echo ==========================================
echo [INFO] Starting Streamlit App - uv powered - debug mode
echo ==========================================

REM Move to script directory
cd /d "%~dp0" || (echo [ERROR] Cannot change to script directory & pause & exit /b 1)
echo [INFO] Working directory: %CD%

REM Config
set "VENV_DIR=.venv"
set "PORT=8501"

REM ------------------------------------------------------------
REM Locate uv (self-healing: install automatically if missing)
REM ------------------------------------------------------------
set "UV="
where uv >nul 2>nul && (
  set "UV=uv"
  echo [INFO] Found uv on PATH
)

if not defined UV (
  if exist "%USERPROFILE%\.cargo\bin\uv.exe" (
    set "UV=%USERPROFILE%\.cargo\bin\uv.exe"
    echo [INFO] Found uv at %USERPROFILE%\.cargo\bin\uv.exe
  )
)

if not defined UV (
  echo [WARN] uv not found. Attempting automatic installation...
  for %%P in (powershell.exe pwsh.exe) do (
    where %%P >nul 2>nul && set "PS=%%P"
    if defined PS goto :HavePS
  )
  echo [ERROR] PowerShell not available; cannot install uv automatically.
  echo        Install manually with:
  echo        powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 ^| iex"
  pause
  exit /b 1

:HavePS
  "%PS%" -NoProfile -ExecutionPolicy Bypass -Command ^
    "try { irm https://astral.sh/uv/install.ps1 ^| iex; exit 0 } catch { $host.ui.WriteErrorLine($_.Exception.Message); exit 1 }"
  if errorlevel 1 (
    echo [ERROR] Automatic uv installation failed.
    echo        Check your internet connection and proxy settings, then try again.
    echo        Or install manually:
    echo        powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 ^| iex"
    pause
    exit /b 1
  )

  REM Re-detect uv after install
  where uv >nul 2>nul && (
    set "UV=uv"
    echo [INFO] uv installed and available on PATH
  )
  if not defined UV (
    if exist "%USERPROFILE%\.cargo\bin\uv.exe" (
      set "UV=%USERPROFILE%\.cargo\bin\uv.exe"
      echo [INFO] uv installed at %USERPROFILE%\.cargo\bin\uv.exe
    )
  )
  if not defined UV (
    echo [ERROR] uv installation finished but uv.exe not found.
    echo        Ensure %USERPROFILE%\.cargo\bin is on your PATH, or re-open the terminal.
    pause
    exit /b 1
  )
)

REM Quick sanity check (nice to have)
"%UV%" --version >nul 2>&1 || (
  echo [ERROR] uv seems unavailable or corrupted.
  pause
  exit /b 1
)

REM Create venv if missing
if not exist "%VENV_DIR%\Scripts\python.exe" (
  echo [INFO] Creating virtual environment with uv in "%VENV_DIR%" using Python 3.11
  "%UV%" venv "%VENV_DIR%" --python 3.11 || (echo [ERROR] uv venv failed & pause & exit /b 1)
) else (
  echo [INFO] Virtual environment already present
)

REM Check if Streamlit is installed in the venv
"%UV%" pip show streamlit -p "%VENV_DIR%" >nul 2>&1
if %errorlevel%==0 (
  echo [INFO] Streamlit already installed in venv
) else (
  if exist requirements.txt (
    echo [INFO] Installing packages from requirements.txt with uv
    "%UV%" pip install -p "%VENV_DIR%" -r requirements.txt || (echo [ERROR] Dependency installation failed & pause & exit /b 1)
  ) else (
    echo [WARN] requirements.txt not found; installing streamlit only
    "%UV%" pip install -p "%VENV_DIR%" streamlit || (echo [ERROR] Streamlit installation failed & pause & exit /b 1)
  )
)

REM Show runtime details
"%VENV_DIR%\Scripts\python.exe" --version || (echo [ERROR] Python in venv not usable & pause & exit /b 1)
"%VENV_DIR%\Scripts\python.exe" -c "import streamlit,sys; print('Streamlit version:', streamlit.__version__); print('Interpreter:', sys.executable)" || (echo [WARN] Could not introspect Streamlit version)

REM Launch Streamlit in foreground so logs stay visible; Streamlit opens browser when ready
echo [INFO] Launching Streamlit in foreground on port %PORT%
call "%VENV_DIR%\Scripts\python.exe" -m streamlit run app.py --server.port=%PORT% --server.headless=false
set "RC=%ERRORLEVEL%"

REM Keep window open if Streamlit exits with error
if not "%RC%"=="0" (
  echo [ERROR] Streamlit exited with code %RC%
  echo        See log above for details
  pause
  endlocal & exit /b %RC%
)

echo [INFO] App stopped normally
endlocal & exit /b 0
