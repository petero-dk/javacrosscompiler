
@echo off
call prepare.bat
echo.
echo.
echo.
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Failed to prepare
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Completed preperation


setlocal enabledelayedexpansion

set START=%~dp0

set VERSION=2.5-SNAPSHOT

for /f tokens^=2-5^ delims^=.-_^" %%j in ('javac -fullversion 2^>^&1') do set "jver=%%j%%k"

echo Found java version %jver%

IF %jver% NEQ 110 ( 
    echo Setting Java to Version 11
    set JAVA_HOME=%JAVA11_HOME%
    set PATH=%JAVA_HOME%\bin;%PATH%
) 


::rmdir /S /Q out

CALL :BUILDCALIMERO calimero-core %VERSION%
cd %START%
call 7za x "%START%source\calimero-core\build\distributions\calimero-core-%VERSION%.zip" -spe -bd -y -o"%START%source\calimero-core\build\distributions\"  > %THIS%logs\r8.%PROJECT%.log 2>&1
call downpile.bat "%START%source\calimero-core\build\distributions\calimero-core-%VERSION%\lib\calimero-core-%VERSION%.jar"

cd %START%


CALL :BUILDCALIMERO calimero-device %VERSION%
cd %START%
call downpile.bat "%START%source\calimero-device\build\libs\calimero-device-%VERSION%.jar" %_result% --lib "%START%source\calimero-core\build\distributions\calimero-core-%VERSION%\lib\calimero-core-%VERSION%.jar"
:: SETS %_result% with found CP
cd %START%


if not exist "%START%tmp\nrjavaserial-3.15.0.jar" wget "https://repo1.maven.org/maven2/com/neuronrobotics/nrjavaserial/3.15.0/nrjavaserial-3.15.0.jar" -O "%START%tmp\nrjavaserial-3.15.0.jar"  > log.log

CALL :BUILDCALIMERO calimero-rxtx %VERSION%
cd %START%
call downpile.bat "%START%source\calimero-rxtx\build\libs\calimero-rxtx-%VERSION%.jar" --lib "%START%tmp\nrjavaserial-3.15.0.jar" %_result% 
cd %START%


EXIT /B 0

:BUILDCALIMERO
    SETLOCAL
    SET PROJECT=%1
    SET VERSION=%2
    echo Building: %PROJECT%-%VERSION%
        
    rmdir /S /Q "%START%source/%PROJECT%"
    call git clone --quiet https://github.com/calimero-project/%PROJECT%.git "%START%source/%PROJECT%"

    cd "%START%source/%PROJECT%"
    call gradlew build -x test

    cd %START%

    ENDLOCAL 
EXIT /B 0
