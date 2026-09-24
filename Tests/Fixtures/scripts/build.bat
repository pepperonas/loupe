@echo off
REM ============================================================
REM  build.bat - builds all projects and packages the release
REM ============================================================
setlocal EnableDelayedExpansion

set "ROOT=%~dp0"
set "OUT=%ROOT%out"
set CONFIG=Release
set /a count=0

if "%1"=="clean" goto :clean
if not exist "%OUT%" mkdir "%OUT%"

:: Build every project below src
for /r "%ROOT%src" %%f in (*.csproj) do (
    echo Building %%~nxf ...
    dotnet build "%%f" -c %CONFIG% -o "%OUT%" >nul || goto :fail
    set /a count+=1
)

echo Built !count! projects at %TIME:~0,8% on %DATE%.
if %ERRORLEVEL% EQU 0 (
    echo Success: 100%% done
) else (
    echo Something went wrong
)
exit /b 0

:clean
rmdir /s /q "%OUT%" 2>nul
echo Cleaned %OUT%
exit /b 0

:fail
echo Build failed with error %ERRORLEVEL% 1>&2
exit /b 1
