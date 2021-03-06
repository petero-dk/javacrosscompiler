@echo off
setlocal enabledelayedexpansion
    
    set THIS=%~dp0

    if not exist %THIS%logs\ mkdir %THIS%logs\

    SET INPUT=%1
    SET PROJECT=%~n1
    SET LIB=%~dp1
    set ALLARGS=%*
    for /f "tokens=1,* delims= " %%a in ("%*") do set CP=%%b

    echo Collecting dependencies: %PROJECT%

    for %%X in ("%LIB%"*.jar) do (
        if NOT "%%X" == "%INPUT%" set CP=!CP! --lib "%%X"
    )


    if exist "%THIS%opt\%PROJECT%\" rmdir /s /Q "%THIS%opt\%PROJECT%\"
    mkdir %THIS%opt\%PROJECT%
    echo Desugaring: %PROJECT%
    echo java -jar "%R8%" --lib "%JAVA18_HOME%\jre\lib\rt.jar" %CP% --output %THIS%opt\%PROJECT%\ --pg-conf "%THIS%keepall.txt" --no-tree-shaking --no-minification "%INPUT%"
    java -jar "%R8%" --lib "%JAVA18_HOME%\jre\lib\rt.jar" %CP% --output %THIS%opt\%PROJECT%\ --pg-conf "%THIS%keepall.txt" --no-tree-shaking --no-minification "%INPUT%"

    IF ERRORLEVEL 1 (
        echo [31m[FAILURE][0m Desugaring failed ^( %ERRORLEVEL% ^)
        EXIT /B 1
    )

    echo Repacking: %PROJECT%
    if exist "%THIS%out\%PROJECT%.jar" del "%THIS%out\%PROJECT%.jar"
    call d2j-dex2jar.bat -f --output "%THIS%out\%PROJECT%.jar" "%THIS%opt\%PROJECT%\classes.dex"

    IF ERRORLEVEL 1 (
        echo [31m[FAILURE][0m Repacking failed
        EXIT /B 1
    )
  ::  cd out\%PROJECT%
  ::  ..\..\tools\7z\7za.exe a  ..\%PROJECT%.jar META-INF\
  ::  ..\..\tools\7z\7za.exe a  ..\%PROJECT%.jar properties.xml
  ::  cd ..\..
  
ENDLOCAL & SET _result=%CP%