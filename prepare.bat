@echo off
set START=%~dp0
set MODE=DEFAULT

:Loop
IF "%1"=="" GOTO Continue
if "%1" EQU "/force" (
    set MODE=FORCE
    set JAVA8_HOME=
    set JAVA11_HOME=
)
if "%1" EQU "/?" GOTO Help

SHIFT
GOTO Loop

:Help
echo Java Cross Compiler - Prepare
echo version 1.0.0
echo.
echo.
ECHO Usage:  prepare [\force] [\help]
ECHO.
GOTO :EOF

:Continue


echo %path%|%SYSTEMROOT%\system32\find /i "%START%tools">nul  || set PATH=%START%tools;%PATH%
echo Running in mode: %MODE%

if "%MODE%" == "FORCE" rmdir /s /Q %START%tmp\
if not exist %START%tmp\ mkdir %START%tmp

if exist %START%logs\ rmdir /s /Q %START%logs\
mkdir %START%logs\

:: INSTALL DEPOT TOOLS FOR WINDOWS
cmd /c "exit /b 0"

if not exist %START%tmp\depot_tools\ (
    echo.
    echo.
    echo Downloading Depot Tools
    wget -nv --no-check-certificate -P %START%tmp\ https://storage.googleapis.com/chrome-infra/depot_tools.zip
    7za x "%START%tmp\depot_tools.zip" -spe -bd -y -o"%START%tmp\depot_tools\" | %SYSTEMROOT%\system32\FIND /V "ing  "

    REM UPDATE TOOLS?

    REM FOR NOW BOOTSTRAP THEM
    echo Bootstrapping Depot Tools
    call "%START%tmp\depot_tools\bootstrap\win_tools.bat"
)
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not get Depot Tools
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Installed Depot Tools

echo %path%|%SYSTEMROOT%\system32\find /i "%START%tmp\depot_tools">nul  || set PATH=%START%tmp\depot_tools;%PATH%


:: INSTALL R8
cmd /c "exit /b 0"
if not exist %START%tmp\r8\ (
    echo.
    echo.
    echo Cloning R8
    call git clone --quiet https://r8.googlesource.com/r8 "%START%tmp\r8"
)
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not get R8
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Cloned R8

:: This is non destructive and sets the error level to number of replacements.
fart "%START%tmp\r8\build.gradle" "http://storage.googleapis.com/r8-deps/maven_mirror/" "https://repo1.maven.org/maven2/" 


cmd /c "exit /b 0"
if not exist %START%tmp\r8\build\libs\d8.jar (
    echo.
    echo.
    echo Building R8
    cd %START%tmp\r8\
    set GRADLE_OPTS=%GRADLE_OPTS% -Dorg.gradle.daemon=false
    call %START%tmp\depot_tools\python "tools\gradle.py" r8
    cd %START%
)

if not exist %START%tmp\r8\build\libs\r8.jar (
    echo [31m[FAILURE][0m Could not build R8
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Found R8

set R8=%START%tmp\r8\build\libs\r8.jar


echo EXIT
REM EXIT /B 0
