@echo off

set START=%~dp0
echo %path%|find /i "%START%tools">nul  || set PATH=%START%tools;%PATH%

if not exist %START%tmp\ mkdir %START%tmp
:: rmdir /s /Q %START%tmp\

for /f tokens^=2-5^ delims^=.-_^" %%j in ('javac -fullversion 2^>^&1') do set "jver=%%j%%k"
echo Found java version %jver%

:: Download and prepare Java8
IF "%JAVA8_HOME%" EQU "" ( 
    echo Getting Java 8
    if not exist "%START%tmp\java18.zip" wget "https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u222-b10/OpenJDK8U-jdk_x86-32_windows_hotspot_8u222b10.zip" -O "%START%tmp\java18.zip" > log.log
    if not exist "%START%tmp\java18\" call 7za x "%START%tmp\java18.zip" -spe -bd -y -o"%START%tmp\java18\" > log.log
    set JAVA8_HOME=%START%tmp\java18\jdk8u222-b10
)

:: Download and prepare Java11
IF "%JAVA11_HOME%" EQU "" ( 
    echo Getting Java 11
    if not exist "%START%tmp\java110.zip" wget "https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%%2B11/OpenJDK11U-jdk_x86-32_windows_hotspot_11.0.4_11.zip" -O "%START%tmp\java110.zip"  > log.log
    if not exist "%START%tmp\java110\" call 7za x "%START%tmp\java110.zip" -spe -bd -y -o"%START%tmp\java110\"  > log.log
    set JAVA11_HOME=%START%tmp\java110\jdk-11.0.4+11
)

IF %jver% NEQ 18 ( 
    echo Setting Java to Version 8
    set JAVA_HOME=%JAVA8_HOME%
    echo %PATH:)=^)%|find /i "%JAVA_HOME%\bin">nul || set path=%JAVA_HOME%\bin;%PATH:)=^)%
) 

:: INSTALL DEPOT TOOLS FOR WINDOWS
if not exist %START%tmp\depot_tools\ (
    echo Getting Depot Tools
    wget https://storage.googleapis.com/chrome-infra/depot_tools.zip -P %START%tmp\ > log.log
    7za x "%START%tmp\depot_tools.zip" -bd -y -o"%START%tmp\depot_tools\"  > log.log
)
echo %path%|find /i "%START%tmp\depot_tools">nul  || set PATH=%START%tmp\depot_tools;%PATH%


:: INSTALL R8
if not exist %START%tmp\r8\ (
    echo Getting R8
    call git clone https://r8.googlesource.com/r8 "%START%tmp\r8" > log.log
    REM Google is missing dependencies in their maven mirror
    fart -q "%START%tmp\r8\build.gradle" "http://storage.googleapis.com/r8-deps/maven_mirror/" "https://repo1.maven.org/maven2/" 
)

if not exist %START%tmp\r8\build\libs\d8.jar (
    echo Building R8
    cd %START%tmp\r8\
    call vpython tools\gradle.py d8 r8
    cd %START%
)
    set R8=%START%tmp\r8\build\libs\r8.jar

:: Dex2Jar with unsafenames disabled
if not exist %START%tmp\dex2jar\ (
    call git clone --single-branch --branch "feature/allowunsafenames" https://github.com/petero-dk/dex2jar.git "%START%tmp\dex2jar"
)

:: Build dex2jar
if not exist %START%tmp\dex-tools\ (
    cd %START%tmp\dex2jar
    call gradlew build
    cd %START%
    7za x "%START%tmp\dex2jar\dex-tools\build\distributions\dex-tools-2.1-SNAPSHOT.zip" -bd -y -o"%START%tmp\dex-tools"  > nul
)
echo %path%|find /i "%START%tmp\dex-tools\dex-tools-2.1-SNAPSHOT">nul  || set PATH=%START%tmp\dex-tools\dex-tools-2.1-SNAPSHOT;%PATH%



















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