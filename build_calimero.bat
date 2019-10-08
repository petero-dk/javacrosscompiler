
@echo off


echo Build Calimero Project to Java 8

setlocal enabledelayedexpansion
::In order to not have to run prepare again
:: To set env variables explicitly
IF "%TOOLSPATH%"=="" ( call prepare.bat ) else set PATH=%TOOLSPATH%;%PATH%

if not exist "%START%out/calimero" mkdir "%START%out/calimero"

set START=%~dp0

set VERSION=2.5-SNAPSHOT

for /f tokens^=2-5^ delims^=.-_^" %%j in ('javac11 -fullversion 2^>^&1') do set "jver=%%j%%k"

echo Found java version %jver%

IF "%jver%" NEQ "110" ( 
    echo Setting Java to Version 11
    set JAVA_HOME=%JAVA11_HOME%
    set path=%JAVA11_HOME%\bin;%PATH:)=^)%
) 

::rmdir /S /Q out

CALL :BUILDCALIMERO calimero-core %VERSION%
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not build calimero-core
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Build calimero-core
cd %START%
call 7za x "%START%source\calimero-core\build\distributions\calimero-core-%VERSION%.zip" -spe -bd -y -o"%START%source\calimero-core\build\distributions\"
call downpile.bat "%START%source\calimero-core\build\distributions\calimero-core-%VERSION%\lib\calimero-core-%VERSION%.jar"

cd %START%

IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not downpile calimero-core
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Downpiled calimero-core


CALL :BUILDCALIMERO calimero-device %VERSION%
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not build calimero-device
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Build calimero-device
cd %START%
call downpile.bat "%START%source\calimero-device\build\libs\calimero-device-%VERSION%.jar" %_result% --lib "%START%source\calimero-core\build\distributions\calimero-core-%VERSION%\lib\calimero-core-%VERSION%.jar"
:: SETS %_result% with found CP
cd %START%

IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not downpile calimero-device
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Downpiled calimero-device


if not exist "%START%tmp\nrjavaserial-3.15.0.jar" wget --no-check-certificate -nv -O "%START%tmp\nrjavaserial-3.15.0.jar" "https://repo1.maven.org/maven2/com/neuronrobotics/nrjavaserial/3.15.0/nrjavaserial-3.15.0.jar" 
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not get nrjavaserial
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Got nrjavaserial

CALL :BUILDCALIMERO calimero-rxtx %VERSION%
IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not build calimero-rxtx
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Build calimero-rxtx
cd %START%
call downpile.bat "%START%source\calimero-rxtx\build\libs\calimero-rxtx-%VERSION%.jar" --lib "%START%tmp\nrjavaserial-3.15.0.jar" %_result% 
cd %START%

IF ERRORLEVEL 1 (
    echo [31m[FAILURE][0m Could not downpile calimero-rxtx
    EXIT /B 1
) ELSE echo [32m[SUCCESS][0m Downpiled calimero-rxtx

move "%START%out\calimero*" "%START%out\calimero\"

GOTO :EOF
::EXIT /B 0

:BUILDCALIMERO
    SETLOCAL
    SET PROJECT=%1
    SET VERSION=%2
    echo Building: %PROJECT%-%VERSION%
        
    :: if exist "%START%source/%PROJECT%" rmdir /S /Q "%START%source/%PROJECT%"
    if not exist "%START%source/%PROJECT%" call git clone --quiet https://github.com/calimero-project/%PROJECT%.git "%START%source/%PROJECT%"
    IF ERRORLEVEL 1 (
        echo [31m[FAILURE][0m Could not clone %PROJECT%
        EXIT /B 1
    ) ELSE echo [32m[SUCCESS][0m Cloned %PROJECT%

    cd "%START%source/%PROJECT%"
    call gradlew build -x test
    IF ERRORLEVEL 1 (
        echo [31m[FAILURE][0m Could not build %PROJECT%
        EXIT /B 1
    ) ELSE echo [32m[SUCCESS][0m Built %PROJECT%

    cd %START%

    ENDLOCAL 
EXIT /B 0
