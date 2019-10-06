@echo off

IF "%1"=="" GOTO Continue
if "%1" EQU "/shutdown" (
    echo shutdown
    shutdown /s /f /t 0
)
if "%1" EQU "/failed" (
    echo failed
    EXIT /B 1
)
if "%1" EQU "/success" (
    echo succcess
    EXIT /B 0
)


:Continue
Echo eof