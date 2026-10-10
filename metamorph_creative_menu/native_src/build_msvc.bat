@echo off
setlocal

set "ROOT=%~dp0.."
set "SRC=%~dp0mcm_native_gameover.c"
set "OBJ=%~dp0mcm_native_gameover.obj"
set "DLL=%ROOT%\mcm_native_gameover.dll"
set "LIB=%ROOT%\mcm_native_gameover.lib"

where cl >nul 2>nul || (
    echo ERROR: cl.exe was not found. Run this from an x86 Native Tools Command Prompt for Visual Studio.
    exit /b 1
)
where link >nul 2>nul || (
    echo ERROR: link.exe was not found. Run this from an x86 Native Tools Command Prompt for Visual Studio.
    exit /b 1
)

cl /nologo /c /O2 /GS- /Zl /TC "%SRC%" /Fo"%OBJ%"
if errorlevel 1 exit /b %errorlevel%

link /nologo /DLL /NOENTRY /NODEFAULTLIB /MACHINE:X86 /DYNAMICBASE /NXCOMPAT /NOSEH /SUBSYSTEM:WINDOWS,6.00 /OUT:"%DLL%" /IMPLIB:"%LIB%" "%OBJ%"
if errorlevel 1 exit /b %errorlevel%

del /q "%OBJ%" >nul 2>nul

echo Built:
echo   %DLL%
echo   %LIB%
exit /b 0
