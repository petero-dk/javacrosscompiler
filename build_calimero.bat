
@echo off

:: To set env variables explicitly
call prepare.bat

echo Build Calimero Project to Java 8

setlocal enabledelayedexpansion

set START=%~dp0

set VERSION=2.5-SNAPSHOT

for /f tokens^=2-5^ delims^=.-_^" %%j in ('javac11 -fullversion 2^>^&1') do set "jver=%%j%%k"

echo Found java version %jver%

IF "%jver%" NEQ "110" ( 
    echo Setting Java to Version 11
    set JAVA_HOME=%JAVA11_HOME%
    set path=%JAVA11_HOME%\bin;%PATH:)=^)%
) 
echo %JAVA_HOME%
echo %PATH%
javac -version

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

GOTO :EOF
::EXIT /B 0

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
