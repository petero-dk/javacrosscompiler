@echo off
setlocal enabledelayedexpansion
    
    set THIS=%~dp0

    SET INPUT=%1
    SET PROJECT=%~n1
    SET LIB=%~dp1
    set ALLARGS=%*
    for /f "tokens=1,* delims= " %%a in ("%*") do set CP=%%b

    echo Desugaring: %PROJECT%

    for %%X in ("%LIB%"*.jar) do (
        if NOT "%%X" == "%INPUT%" set CP=!CP! --lib "%%X"
    )

    mkdir %THIS%opt\%PROJECT%
    java -jar %R8% --lib "%JAVA8_HOME%\jre\lib\rt.jar" %CP% --output %THIS%opt\%PROJECT%\ --pg-conf "%THIS%keepall.txt" --no-tree-shaking --no-minification "%INPUT%" > %THIS%logs\r8.%PROJECT%.log 2>&1


    echo Repacking: %PROJECT%
    call d2j-dex2jar.bat -f --output "%START%out\%PROJECT%.jar" "%START%opt\%PROJECT%\classes.dex" > %THIS%logs\dj2.%PROJECT%.log 2>&1

  ::  cd out\%PROJECT%
  ::  ..\..\tools\7z\7za.exe a  ..\%PROJECT%.jar META-INF\
  ::  ..\..\tools\7z\7za.exe a  ..\%PROJECT%.jar properties.xml
  ::  cd ..\..

ENDLOCAL & SET _result=%CP%