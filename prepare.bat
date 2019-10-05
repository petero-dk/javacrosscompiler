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

where javac

echo %path%|%SYSTEMROOT%\system32\find /i "%START%tools">nul  || set PATH=%START%tools;%PATH%
echo Running in mode: %MODE%

if "%MODE%" == "FORCE" rmdir /s /Q %START%tmp\
if not exist %START%tmp\ mkdir %START%tmp

if exist %START%logs\ rmdir /s /Q %START%logs\
mkdir %START%logs\

call javas /v /jdk

:: Download and prepare Java8
cmd /c "exit /b 0"
IF "%JAVA18_HOME%" EQU "" ( 
    echo.
    echo.
    echo Downloading Java 8
    if not exist "%START%tmp\java18.zip" wget -nv -O "%START%tmp\java18.zip" "https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u222-b10/OpenJDK8U-jdk_x86-32_windows_hotspot_8u222b10.zip" 
    echo Extracting Java 8
    if not exist "%START%tmp\java18\" call 7za x "%START%tmp\java18.zip" -spe -bd -y -o"%START%tmp\java18\"  | %SYSTEMROOT%\system32\FIND /V "ing  "
    set JAVA18_HOME=%START%tmp\java18\jdk8u222-b10
    echo.
)
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not get Java 8
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Installed Java 8

:: Download and prepare Java11
cmd /c "exit /b 0"
IF "%JAVA11_HOME%" EQU "" ( 
    echo.
    echo.
    echo Downloading Java 11
    if not exist "%START%tmp\java110.zip" wget -nv -O "%START%tmp\java110.zip" "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%%2B11/OpenJDK11U-jdk_x86-32_windows_hotspot_11.0.4_11.zip"
    echo Extracting Java 11
    if not exist "%START%tmp\java110\" call 7za x "%START%tmp\java110.zip" -spe -bd -y -o"%START%tmp\java110\" | %SYSTEMROOT%\system32\FIND /V "ing  "
    set JAVA11_HOME=%START%tmp\java110\jdk-11.0.4+11
)
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not get Java 11
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Installed Java 11

IF "%jver%" NEQ "18" ( 
    echo.
    echo.
    echo Setting Java to Version 8
    set JAVA_HOME=%JAVA18_HOME%
    echo %PATH:)=^)%|%SYSTEMROOT%\system32\find /i "%JAVA_HOME%\bin">nul || set path=%JAVA_HOME%\bin;%PATH:)=^)%
) 

:: INSTALL DEPOT TOOLS FOR WINDOWS
cmd /c "exit /b 0"

if not exist %START%tmp\depot_tools\ (
    echo.
    echo.
    echo Downloading Depot Tools
    wget -nv  -P %START%tmp\ https://storage.googleapis.com/chrome-infra/depot_tools.zip
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


:: If python is in path, use that
where python

call python -V
call %START%tmp\depot_tools\python -V

cmd /c "exit /b 0"
if not exist %START%tmp\r8\build\libs\d8.jar (
    echo.
    echo.
    echo Building R8
    cd %START%tmp\r8\

    call %START%tmp\depot_tools\python "tools\gradle.py" d8 r8
    cd %START%
)

if not exist %START%tmp\r8\build\libs\d8.jar (
    echo [31m[FAILURE][0m Could not build R8
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Found R8

set R8=%START%tmp\r8\build\libs\r8.jar

:: Dex2Jar with unsafenames disabled
if not exist %START%tmp\dex2jar\ (
    echo.
    echo.
    echo Getting Dex2Jar
    call git clone --quiet --single-branch --branch "feature/allowunsafenames" https://github.com/petero-dk/dex2jar.git "%START%tmp\dex2jar"
)
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not get Dex2Jar
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Cloned Dex2Jar

:: Build dex2jar
if not exist %START%tmp\dex-tools\ (
    echo.
    echo.
    echo Building Dex2Jar
    cd %START%tmp\dex2jar
    call gradlew build --warn
    cd %START%
    7za x "%START%tmp\dex2jar\dex-tools\build\distributions\dex-tools-2.1-SNAPSHOT.zip" -bd -y -o"%START%tmp\dex-tools"  > nul
)

IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not build Dex2Jar
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Built Dex2Jar

echo %path%|%SYSTEMROOT%\system32\find /i "%START%tmp\dex-tools\dex-tools-2.1-SNAPSHOT">nul  || set PATH=%START%tmp\dex-tools\dex-tools-2.1-SNAPSHOT;%PATH%




EXIT /B 0















:: INSTALL GRADLEW 
:: wget https://services.gradle.org/distributions/gradle-5.6.2-bin.zip -O "%START%tmp\gradle.zip"
:: 7za x "%START%tmp\gradle.zip" -bd -y -o"%START%tmp\gradle\"
::  set PATH=%START%tmp\gradle\gradle-5.6.2\bin;%PATH%


:: INSTALL PYTHON 
:: WHERE python55
:: IF %ERRORLEVEL% NEQ 0 ( 
::   wget "https://github.com/winpython/winpython/releases/download/2.1.20190928/Winpython32-3.7.4.1Zero.exe" -O "%START%tmp\python37.exe"
::    "%START%tmp\python37.exe" -y -o"%START%tmp\python37\" > nul
:: )