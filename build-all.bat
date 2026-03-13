@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo   trex - Tree Explorer :: Build Script
echo   Author: Windneiro
echo ============================================================
echo.

:: Check if zig is available
where zig >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] zig not found in PATH.
    echo         Please install Zig 0.13.0 from https://ziglang.org/download/
    exit /b 1
)

for /f "tokens=*" %%v in ('zig version') do set ZIG_VER=%%v
echo [INFO] Using Zig %ZIG_VER%
echo.

:: Output directory
if not exist "dist" mkdir dist

:: ──────────────────────────────────────────
:: Build: Windows x86_64
:: ──────────────────────────────────────────
echo [BUILD] Windows x86_64 ...
zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe
if %errorlevel% neq 0 ( echo [FAIL] Windows x86_64 failed & exit /b 1 )
copy /Y "zig-out\bin\trex.exe" "dist\trex-windows-x86_64.exe" >nul
echo [OK]   dist\trex-windows-x86_64.exe

:: ──────────────────────────────────────────
:: Build: Windows arm64
:: ──────────────────────────────────────────
echo [BUILD] Windows arm64 ...
zig build -Dtarget=aarch64-windows -Doptimize=ReleaseSafe
if %errorlevel% neq 0 ( echo [WARN] Windows arm64 failed ^(skipped^) ) else (
    copy /Y "zig-out\bin\trex.exe" "dist\trex-windows-arm64.exe" >nul
    echo [OK]   dist\trex-windows-arm64.exe
)

:: ──────────────────────────────────────────
:: Build: Linux x86_64
:: ──────────────────────────────────────────
echo [BUILD] Linux x86_64 ...
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseSafe
if %errorlevel% neq 0 ( echo [FAIL] Linux x86_64 failed & exit /b 1 )
copy /Y "zig-out\bin\trex" "dist\trex-linux-x86_64" >nul
echo [OK]   dist\trex-linux-x86_64

:: ──────────────────────────────────────────
:: Build: Linux arm64
:: ──────────────────────────────────────────
echo [BUILD] Linux arm64 ...
zig build -Dtarget=aarch64-linux -Doptimize=ReleaseSafe
if %errorlevel% neq 0 ( echo [WARN] Linux arm64 failed ^(skipped^) ) else (
    copy /Y "zig-out\bin\trex" "dist\trex-linux-arm64" >nul
    echo [OK]   dist\trex-linux-arm64
)

:: ──────────────────────────────────────────
:: Build: macOS x86_64
:: ──────────────────────────────────────────
echo [BUILD] macOS x86_64 ...
zig build -Dtarget=x86_64-macos -Doptimize=ReleaseSafe
if %errorlevel% neq 0 ( echo [WARN] macOS x86_64 failed ^(skipped^) ) else (
    copy /Y "zig-out\bin\trex" "dist\trex-macos-x86_64" >nul
    echo [OK]   dist\trex-macos-x86_64
)

:: ──────────────────────────────────────────
:: Build: macOS arm64 (Apple Silicon)
:: ──────────────────────────────────────────
echo [BUILD] macOS arm64 (Apple Silicon) ...
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSafe
if %errorlevel% neq 0 ( echo [WARN] macOS arm64 failed ^(skipped^) ) else (
    copy /Y "zig-out\bin\trex" "dist\trex-macos-arm64" >nul
    echo [OK]   dist\trex-macos-arm64
)

echo.
echo ============================================================
echo   Done! Binaries are in .\dist\
echo ============================================================
dir /b dist
endlocal
