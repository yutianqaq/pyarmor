REM --------------------------------------------------------------
REM DEPRECATED from v4.4, use pack-obfuscated-scripts.bat instead.
REM --------------------------------------------------------------

@ECHO OFF
REM
REM Sample script used to distribute obfuscated python scripts with cx_Freeze 5.
REM
REM Before run it, all TODO variables need to set correctly.
REM

SetLocal

REM TODO: zip used to update library.zip
Set ZIP=zip
Set PYTHON=C:\Python34\python.exe

REM TODO: Where to find pyarmor.py
Set PYARMOR_PATH=C:\Python34\Lib\site-packages\pyarmor

REM TODO: Absolute path in which all python scripts will be obfuscated
Set SOURCE=D:\projects\pyarmor\src\examples\cx_Freeze

REM TODO: Output path of cx_Freeze
REM       An executable binary file generated by cx_Freeze should be here
Set BUILD_PATH=build\exe.win32-3.4
Set OUTPUT=%SOURCE%\%BUILD_PATH%

REM TODO: Library name, used to archive python scripts in path %OUTPUT%
Set LIBRARYZIP=python34.zip

REM TODO: Entry script filename, must be relative to %SOURCE%
Set ENTRY_NAME=hello
Set ENTRY_SCRIPT=%ENTRY_NAME%.py
Set ENTRY_EXE=%ENTRY_NAME%.exe

REM TODO: output path for saving project config file, and obfuscated scripts
Set PROJECT=D:\projects\pyarmor\src\examples\build-for-freeze

REM TODO: Comment netx line if not to test obfuscated scripts
Set TEST_OBFUSCATED_SCRIPTS=1

REM Check Python
%PYTHON% --version
If NOT ERRORLEVEL 0 (
    Echo.
    Echo Python doesn't work, check value of variable PYTHON
    Echo.
    Goto END
)

REM Check Zip
%ZIP% --version > NUL
If NOT ERRORLEVEL 0 (
    Echo.
    Echo Zip doesn't work, check value of variable ZIP
    Echo.
    Goto END
)

REM Check PyArmor
If NOT EXIST "%PYARMOR_PATH%\pyarmor.py" (
    Echo.
    Echo No pyarmor found, check value of variable PYARMOR_PATH
    Echo.
    Goto END
)

REM Check Source
If NOT EXIST "%SOURCE%" (
    Echo.
    Echo No %SOURCE% found, check value of variable SOURCE
    Echo.
    Goto END
)

REM Check entry script
If NOT EXIST "%SOURCE%\%ENTRY_SCRIPT%" (
    Echo.
    Echo No %ENTRY_SCRIPT% found, check value of variable ENTRY_SCRIPT
    Echo.
    Goto END
)

REM Create a project
Echo.
Cd /D %PYARMOR_PATH%
%PYTHON% pyarmor.py init --type=app --src=%SOURCE% --entry=%ENTRY_SCRIPT% %PROJECT%
If NOT ERRORLEVEL 0 Goto END

REM Change to project path, there is a convenient script pyarmor.bat
cd /D %PROJECT%

REM This is the key, change default runtime path, otherwise dynamic library _pytransform could not be found
Echo.
Call pyarmor.bat config --runtime-path="" --package-runtime=0 --manifest "global-include *.py, exclude %ENTRY_SCRIPT% setup.py pytransform.py, prune build, prune dist"

REM Obfuscate scripts without runtime files, only obfuscated scripts are generated
Echo.
Call pyarmor.bat build --no-runtime
If NOT ERRORLEVEL 0 Goto END

REM Copy pytransform.py and obfuscated entry script to source
Echo.
Echo Copy pytransform.py to %SOURCE%
Copy %PYARMOR_PATH%\pytransform.py %SOURCE%

Echo Backup original %ENTRY_SCRIPT%
Copy %SOURCE%\%ENTRY_SCRIPT% %ENTRY_SCRIPT%.bak

Echo Move modified entry script %ENTRY_SCRIPT% to %SOURCE%
Move dist\%ENTRY_SCRIPT% %SOURCE%

REM Run cx_Freeze setup script
Echo.
SetLocal
    Cd /D %SOURCE%
    %PYTHON% setup.py build
    If NOT ERRORLEVEL 0 Goto END
EndLocal

Echo.
Echo Restore entry script
Move %ENTRY_SCRIPT%.bak %SOURCE%\%ENTRY_SCRIPT%

REM Generate runtime files only
Echo.
Call pyarmor.bat build --only-runtime --output runtime-files
If NOT ERRORLEVEL 0 Goto END
Echo.

Echo Copy runtime files to %OUTPUT%
Copy runtime-files\*.key runtime-files\*.lic runtime-files\_pytransform.dll %OUTPUT%

Echo.
Echo Compile obfuscated script .py to .pyc
%PYTHON% -m compileall -b dist
If NOT ERRORLEVEL 0 Goto END
Echo.

REM Replace the original python scripts with obfuscated scripts in zip file
Echo.
SetLocal
    Cd dist
    %ZIP% -r %OUTPUT%\%LIBRARYZIP% *.pyc
    If NOT "%ERRORLEVEL%" == "0" Goto END
EndLocal

Echo.
Echo All the python scripts have been obfuscated in the output path %OUTPUT% successfully.
Echo.

REM Test obfuscated scripts
If "%TEST_OBFUSCATED_SCRIPTS%" == "1" (
    Echo.
    Echo Prepare to run %ENTRY_EXE% with obfuscated scripts
    Pause

    Cd /D %OUTPUT%
    %ENTRY_EXE%
)

:END

EndLocal
Pause
