@echo off

rem --------------------------------------------------
rem A Windows batch file to slim down NVIDIA drivers.
rem Author: XhmikosR
rem Licensed under the MIT License
rem See help for more info
rem --------------------------------------------------


:start
setlocal

rem Folders kept per build type. To add a new type, define FOLDERS_<TYPE>
rem here and add <TYPE> to KNOWN_TYPES below.
set "FOLDERS_MINIMAL=Display.Driver NVI2"
set "FOLDERS_SLIM=Display.Driver HDAudio NVI2 PhysX PPC"
set "FILES_TO_KEEP=EULA.txt ListDevices.txt setup.cfg setup.exe"

rem Build types accepted by -type; "all" builds every real type
set "KNOWN_TYPES=minimal slim all"

set "BATCH_FILENAME=%~nx0"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_VERSION=0.5"

set "FULL_PATH="
set "BUILD_TYPE="
set "NO_COMPRESS="

rem Parse the arguments in any order: -type <type> and the driver file
:parse_args
if "%~1" == "" goto args_done

if /i "%~1" == "--help" goto help
if /i "%~1" == "-help" goto help
if /i "%~1" == "/help" goto help
if /i "%~1" == "/?" goto help

if /i "%~1" == "-type"  (set "BUILD_TYPE=%~2" & shift & shift & goto parse_args)
if /i "%~1" == "--type" (set "BUILD_TYPE=%~2" & shift & shift & goto parse_args)
if /i "%~1" == "/type"  (set "BUILD_TYPE=%~2" & shift & shift & goto parse_args)

if /i "%~1" == "-no-compress"  (set "NO_COMPRESS=1" & shift & goto parse_args)
if /i "%~1" == "--no-compress" (set "NO_COMPRESS=1" & shift & goto parse_args)
if /i "%~1" == "/no-compress"  (set "NO_COMPRESS=1" & shift & goto parse_args)

rem Anything else starting with - or / is an unrecognized option
set "CURRENT_ARG=%~1"
if "%CURRENT_ARG:~0,1%" == "-" goto unknown_arg
if "%CURRENT_ARG:~0,1%" == "/" goto unknown_arg

rem First non-flag argument is the driver file; a second one is an error
rem Resolve to a full path now, before the cd below changes the directory
if defined FULL_PATH goto unknown_arg
set "FULL_PATH=%~f1"
set "FILENAME=%~n1"
shift
goto parse_args

:unknown_arg
echo. & echo *** [ERROR] Unknown argument: "%~1" & echo.
goto exit

:args_done
rem No driver file means there's nothing to do
if not defined FULL_PATH goto help

rem Default to slim, but point out the other types
if not defined BUILD_TYPE (
  set "BUILD_TYPE=slim"
  echo No build type specified, defaulting to "slim". Other types: %KNOWN_TYPES% ^(use -type^)
  echo.
)

title %BATCH_FILENAME% %FILENAME%

rem Reject an unknown build type before doing any work
set "VALID_TYPE="
for %%T in (%KNOWN_TYPES%) do if /i "%%T" == "%BUILD_TYPE%" set "VALID_TYPE=1"
if not defined VALID_TYPE (
  echo. & echo *** [ERROR] Unknown build type "%BUILD_TYPE%". Valid types: %KNOWN_TYPES% & echo.
  goto exit
)

rem Switch to the batch file's directory (SCRIPT_DIR is captured before any
rem shift, since a bare shift moves %0 and would break %~dp0 here)
cd /d "%SCRIPT_DIR%"

rem Try to detect 7-Zip or 7za.exe; if none is found, show a message and exit
set "SEVENZIP="
call :detect_sevenzip_path

if not exist "%SEVENZIP%" (
  echo 7-Zip or 7za.exe wasn't found!
  echo You can install 7-Zip, or place 7za.exe in your %%PATH%%, or in the same folder as this script.
  goto exit
)

rem If the file doesn't exist show a message and exit
if not exist "%FULL_PATH%" (
  echo "%FULL_PATH%" wasn't found! & goto exit
)

rem Expand "all" into the real types to build
if /i "%BUILD_TYPE%" == "all" (
  set "TYPES_TO_BUILD=minimal slim"
) else (
  set "TYPES_TO_BUILD=%BUILD_TYPE%"
)

rem Extract to a fresh, unique folder so a previous run isn't clobbered
call :find_unique "%FILENAME%" ""
set "WORK_FOLDER=%UNIQUE_PATH%"

rem Extract the driver
"%SEVENZIP%" x "%FULL_PATH%" -o"%WORK_FOLDER%"
if %ERRORLEVEL% neq 0 (
  echo. & echo *** [ERROR] Extracting "%FULL_PATH%" failed! & echo.
  if exist "%WORK_FOLDER%" rd /q /s "%WORK_FOLDER%"
  goto exit
)

rem Work inside the extracted folder
pushd "%WORK_FOLDER%"

rem The kept files are identical for every type, so prepare setup.cfg once
call :modify_setup_cfg
if ERRORLEVEL 1 goto cleanup

rem Build each requested archive straight from the extracted folders
for %%T in (%TYPES_TO_BUILD%) do (
  call :build_variant "%%T"
  if ERRORLEVEL 1 goto cleanup
)

:cleanup
popd
if exist "%WORK_FOLDER%" rd /q /s "%WORK_FOLDER%"


:exit
echo. & echo Press any key to close this window...
pause >nul
endlocal
exit /b


rem Subroutines
:help
echo --------------------------------------------------
echo %BATCH_FILENAME% v%SCRIPT_VERSION%
echo A Windows batch file to slim down NVIDIA drivers.
echo Author: XhmikosR
echo Licensed under the MIT License
echo.
echo Requirements:
echo   * a) 7-Zip installed or b) 7za.exe in your %%PATH%%, or in the same folder as this script
echo   * A recent Windows version; the script is only tested on Windows 11
echo   * The NVIDIA driver already downloaded somewhere on your computer :)
echo.
echo Usage: %BATCH_FILENAME% [-type minimal^|slim^|all] [-no-compress] NVIDIA_DRIVER_FILE.exe
echo.
echo Arguments can be given in any order, e.g.:
echo   %BATCH_FILENAME% -type slim NVIDIA_DRIVER_FILE.exe
echo   %BATCH_FILENAME% NVIDIA_DRIVER_FILE.exe --type slim
echo.
echo Build types:
echo   * minimal - only the driver
echo   * slim    - the driver, HDAudio, PhysX and USB-C HDMI Driver (default)
echo   * all     - both of the above
echo.
echo -no-compress leaves the slimmed driver as a folder instead of a .7z archive.
echo 7-Zip is still needed to extract the driver.
echo --------------------------------------------------
goto exit


:modify_setup_cfg
rem Remove the files required after 397.93, but are not needed
findstr /v "EulaHtmlFile FunctionalConsentFile PrivacyPolicyFile" "setup.cfg" > "setup.tmp"
if ERRORLEVEL 1 (
  echo. & echo *** [ERROR] Editing setup.cfg failed! & echo.
  exit /b 1
)

rem Overwrite the original setup.cfg file
move /y "setup.tmp" "setup.cfg" >nul
if ERRORLEVEL 1 exit /b 1

exit /b 0


:build_variant
rem Resolve FOLDERS_<type> and build that variant
set "VARIANT=%~1"
call set "FOLDERS=%%FOLDERS_%VARIANT%%%"
if not defined FOLDERS (
  echo. & echo *** [ERROR] No folder list defined for build type "%VARIANT%"! & echo.
  exit /b 1
)

rem Bail if a wanted folder is missing
for %%G in (%FOLDERS%) do (
  if not exist "%%G\" (
    echo. & echo *** [ERROR] "%%G" doesn't exist in the drivers file! & echo.
    exit /b 1
  )
)

rem Bail if a wanted file is missing
for %%G in (%FILES_TO_KEEP%) do (
  if not exist "%%G" (
    echo. & echo *** [ERROR] "%%G" doesn't exist in the drivers file! & echo.
    exit /b 1
  )
)

rem Compress into a .7z, or with -no-compress just copy the slimmed folder
if defined NO_COMPRESS (
  call :copy_variant "%VARIANT%" "%FOLDERS%"
) else (
  call :create_archive "%VARIANT%" "%FOLDERS%"
)
exit /b %ERRORLEVEL%


:create_archive
rem %1 = variant name, %2 = space separated list of folders to include
set "VARIANT=%~1"
set "FOLDERS=%~2"

rem Pick a unique name so a previous run's archive isn't overwritten
call :find_unique "..\%FILENAME%_%VARIANT%" ".7z"
set "ARCHIVE_PATH=%UNIQUE_PATH%"
for %%A in ("%ARCHIVE_PATH%") do set "ARCHIVE=%%~nxA"

rem Create the archive directly from the kept folders and files
"%SEVENZIP%" a -t7z "%ARCHIVE_PATH%" %FOLDERS% %FILES_TO_KEEP% -mmt=on -m0=LZMA2 -mx9
if %ERRORLEVEL% neq 0 (
  echo. & echo *** [ERROR] Creating "%ARCHIVE%" failed! & echo.
  exit /b 1
)

rem Verify the archive we just created
"%SEVENZIP%" t "%ARCHIVE_PATH%" >nul
if %ERRORLEVEL% neq 0 (
  echo. & echo *** [ERROR] Verifying "%ARCHIVE%" failed! & echo.
  exit /b 1
)

exit /b 0


:copy_variant
rem %1 = variant name, %2 = folders to include; copies the slimmed set to a folder
set "VARIANT=%~1"
set "FOLDERS=%~2"

rem Pick a unique folder name so a previous run isn't overwritten
call :find_unique "..\%FILENAME%_%VARIANT%" ""
set "OUT_DIR=%UNIQUE_PATH%"
for %%A in ("%OUT_DIR%") do set "OUT_NAME=%%~nxA"

echo. & echo Creating slimmed folder "%OUT_NAME%"...
mkdir "%OUT_DIR%"

rem Copy the kept folders
for %%G in (%FOLDERS%) do (
  xcopy "%%G" "%OUT_DIR%\%%G\" /e /i /q /h /k >nul
  if ERRORLEVEL 1 (
    echo. & echo *** [ERROR] Copying "%%G" failed! & echo.
    exit /b 1
  )
)

rem Copy the kept files
for %%G in (%FILES_TO_KEEP%) do (
  copy /y "%%G" "%OUT_DIR%\" >nul
  if ERRORLEVEL 1 (
    echo. & echo *** [ERROR] Copying "%%G" failed! & echo.
    exit /b 1
  )
)

exit /b 0


:find_unique
rem %1 = base path, %2 = suffix (".7z" for a file, "" for a folder)
rem Sets UNIQUE_PATH to base+suffix, or base_N+suffix if that already exists
set "UNIQUE_PATH=%~1%~2"
set "_u=1"
:find_unique_next
if not exist "%UNIQUE_PATH%" exit /b 0
set "UNIQUE_PATH=%~1_%_u%%~2"
set /a _u+=1
goto find_unique_next


:detect_sevenzip_path
rem Prefer a 7za.exe sitting next to this script
if exist "%SCRIPT_DIR%7za.exe" (set "SEVENZIP=%SCRIPT_DIR%7za.exe" & exit /b)

for %%G in (7z.exe) do (set "SEVENZIP_PATH=%%~$PATH:G")
if exist "%SEVENZIP_PATH%" (set "SEVENZIP=%SEVENZIP_PATH%" & exit /b)

for %%G in (7za.exe) do (set "SEVENZIP_PATH=%%~$PATH:G")
if exist "%SEVENZIP_PATH%" (set "SEVENZIP=%SEVENZIP_PATH%" & exit /b)

for /f "tokens=2*" %%A in (
  'reg QUERY "HKLM\SOFTWARE\7-Zip" /v "Path" 2^>nul ^| find "REG_SZ" ^|^|
   reg QUERY "HKLM\SOFTWARE\Wow6432Node\7-Zip" /v "Path" 2^>nul ^| find "REG_SZ"') do set "SEVENZIP=%%B\7z.exe"
exit /b 0
