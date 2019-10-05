@echo off
setlocal enableDelayedExpansion

set START=%~dp0
set app=java
set MODE=Q

:Loop
IF "%1"=="" GOTO Continue
if "%1" EQU "/jdk" set app=javac
if "%1" EQU "/verbose" set "MODE=verbose"
if "%1" EQU "/v" set "MODE=verbose"
if "%1" EQU "/?" GOTO Help

SHIFT
GOTO Loop

:Help
echo Java Cross Compiler - Get Available Java Versions
echo version 1.0.0
echo.
echo.
ECHO Usage:  prepare [\jdk|jre] [\help] [(\v)erbose]
ECHO.
ECHO \jdk look for javac
ECHO \jre look for java (default)
ECHO.
GOTO :EOF

:Continue

IF "%MODE%"=="verbose" echo Searching for %app% in %%PATH%%
SET FOUNDJAVAS=""
FOR /f "tokens=* delims=(=" %%G IN ('where %app%') DO (
    set bin=%%~dpG
    set home=!bin:\bin=!
    call :GETJAVAVERSION "%%G"
    IF "%MODE%"=="verbose" echo Found Java !JAVAMAJOR!.!JAVAMINOR! in !home!
    :: Create one veriable to hold all found paths
    set FOUNDJAVAS=%FOUNDJAVAS% "!JAVAMAJOR!;!home!" "!JAVAMAJOR!!JAVAMINOR!;!home!"
)

SET CUSTOMLOCATIONS="C:\Program Files\Java\" 
for %%C in (%CUSTOMLOCATIONS%) do ( 
    IF "%MODE%"=="verbose" echo Searching for %app% in %%C

    for /R "%%C" %%F in (%app%) do (
        IF EXIST %%F (
            set bin=%%~dpF
            set home=!bin:\bin=!
            call :GETJAVAVERSION "%%F"
            IF "%MODE%"=="verbose" echo Found Java !JAVAMAJOR!.!JAVAMINOR! in !home!
            :: Create one veriable to hold all found paths
            set FOUNDJAVAS=!FOUNDJAVAS! "!JAVAMAJOR!;!home!" "!JAVAMAJOR!!JAVAMINOR!;!home!"
        )
    )
)

IF "%MODE%"=="verbose" echo Done searching for %app%


:: Split the holding variable by space and then by ; and " in order to get version and path. 
:: All on one line to utilize bat file line scoping and expansion
endlocal & for %%V in (%FOUNDJAVAS%) do ( for /F delims^=^"^;^ tokens^=1-2 %%u in ('echo %%V') do ( set "JAVA%%u_HOME=%%v" ) )
EXIT /B 0

:GETJAVAVERSION
    SETLOCAL
    set J=%1
    for /f tokens^=2-5^ delims^=.-_^" %%j in ('%J% -fullversion 2^>^&1') do (
        set "major=%%j"
        set "minor=%%k"
    )
    ENDLOCAL & SET "JAVAMAJOR=%major%" & SET "JAVAMINOR=%minor%"
EXIT /B 0
