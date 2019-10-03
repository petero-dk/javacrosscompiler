@echo off

call prepare.bat


setlocal enabledelayedexpansion

set START=%~dp0

set VERSION=2.5-SNAPSHOT

for /f tokens^=2-5^ delims^=.-_^" %%j in ('javac -fullversion 2^>^&1') do set "jver=%%j%%k"

echo Found java version %jver%
IF %jver% NEQ 110 ( 
    echo Setting Java to Version 11
    set JAVA_HOME=%JAVA11_HOME%
) 
set JAVA_HOME=C:\Program Files\Zulu\zulu-11
set PATH=%JAVA_HOME%\bin;%PATH%


::rmdir /S /Q out
:: CALL :BUILDCALIMERO calimero-core %VERSION%
cd %START%
CALL :DESUGAR calimero-core %VERSION%
cd %START%

EXIT /B 0

CALL :BUILDCALIMERO calimero-device %VERSION%
cd %START%
CALL :DESUGAR calimero-device %VERSION%  %_result% --lib "%START%out\calimero-core-%VERSION%\lib\calimero-core-%VERSION%.jar"
:: SETS %_result% with found CP
cd %START%


if not exist "%START%tmp\nrjavaserial-3.15.0.jar" wget "https://repo1.maven.org/maven2/com/neuronrobotics/nrjavaserial/3.15.0/nrjavaserial-3.15.0.jar" -O "%START%tmp\nrjavaserial-3.15.0.jar"  > log.log

CALL :BUILDCALIMERO calimero-rxtx %VERSION%
cd %START%
CALL :DESUGAR calimero-rxtx %VERSION% --lib "%START%tmp\nrjavaserial-3.15.0.jar" %_result%
cd %START%


EXIT /B 0

:BUILDCALIMERO
    SETLOCAL
    SET PROJECT=%1
    SET VERSION=%2
    echo Building: %PROJECT%-%VERSION%
        
    rmdir /S /Q "%START%%PROJECT%"
    call git clone https://github.com/calimero-PROJECT/%PROJECT%.git

    cd "%START%%PROJECT%"
    call gradlew build -x test

    cd %START%

    IF EXIST "%PROJECT%\build\distributions\%PROJECT%-%VERSION%.zip" (    
        copy "%PROJECT%\build\distributions\%PROJECT%-%VERSION%.zip" "%START%out\"
        cd "%START%out"
        tar -xf %PROJECT%-%VERSION%.zip
        cd "%START%"
    ) ELSE (
        mkdir "%START%out\%PROJECT%-%VERSION%\lib"
        copy "%PROJECT%\build\libs\%PROJECT%-%VERSION%.jar" "%START%out\%PROJECT%-%VERSION%\lib\"
    )


    ENDLOCAL 
    ::& SET _result=%_var2%
EXIT /B 0

:DESUGAR
    SETLOCAL
    SET PROJECT=%1
    SET VERSION=%2
    set ALLARGS=%*
    SET FIRSTARGS=%1 %2    
    for /f "tokens=2,* delims= " %%a in ("%*") do set CP=%%b
    ::set CP=%*
    echo %PROJECT%
    echo %VERSION%
    echo %CP%

    echo Desugaring: %PROJECT%-%VERSION%
    set LIB=out\%PROJECT%-%VERSION%\lib

    for %%X in ("%LIB%"\*.jar) do (
        if NOT "%%X" == "%LIB%\%PROJECT%-%VERSION%.jar" set CP=!CP! --lib "%%X"
    )

    mkdir out\%PROJECT%

    java -jar %R8% --lib "%START%tmp\java18\jdk8u222-b10\jre\lib\rt.jar" %CP% --output out\%PROJECT%\ --pg-conf keepall.txt --no-tree-shaking --no-minification "%LIB%\%PROJECT%-%VERSION%.jar"

    call d2j-dex2jar.bat -f --output "%START%out\%PROJECT%.jar" "%START%out\%PROJECT%\classes.dex"

    cd out\%PROJECT%
  ::  ..\..\tools\7z\7za.exe a  ..\%PROJECT%.jar META-INF\
  ::  ..\..\tools\7z\7za.exe a  ..\%PROJECT%.jar properties.xml
    cd ..\..

    ENDLOCAL & SET _result=%CP%
EXIT /B 0

