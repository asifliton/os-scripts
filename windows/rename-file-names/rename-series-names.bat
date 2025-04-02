@echo off
setlocal enabledelayedexpansion

:: Initialize variables with default values
set "appendString="
set "folder=%cd%"
set "previewMode=0"
set "backupMode=0"
set "detailMode=0"

:: Parse command-line arguments
goto :parse_args %*

:: Function to parse command-line arguments
:parse_args
if "%1"=="" goto :validate_args

:: Check for append string flag (-a)
if /i "%1"=="-a" (
    if "%2"=="" (
        echo Error: Missing value for -a parameter.
        goto :help
    )
    set "appendString=%2"
    shift
    shift
    goto :parse_args
)

:: Check for directory flag (-d)
if /i "%1"=="-d" (
    if "%2"=="" (
        echo Error: Missing value for -d parameter.
        goto :help
    )
    set "folder=%2"
    shift
    shift
    goto :parse_args
)

:: Check for preview flag (-p)
if /i "%1"=="-p" (
    set "previewMode=1"
    shift
    goto :parse_args
)

:: Check for backup flag (-b)
if /i "%1"=="-b" (
    set "backupMode=1"
    shift
    goto :parse_args
)

:: Check for detail flag (-d)
if /i "%1"=="-l" (
    set "detailMode=1"
    shift
    goto :parse_args
)

:: Check for help flag (--help or -h)
if /i "%1"=="--help" goto :help
if /i "%1"=="-h" goto :help

:: If an unrecognized flag is encountered
echo Error: Unrecognized flag "%1". Use --help or -h for usage information.
exit /b 1

:: Validate arguments before proceeding
:validate_args
if "%appendString%"=="" (
    echo Error: No append string specified. Use -a flag to provide a base name.
    goto :help
)

:: Trim spaces from append string and check if it's empty
for /f "tokens=*" %%a in ("%appendString%") do set "appendString=%%a"
if "%appendString%"=="" (
    echo Error: Base name cannot be empty.
    exit /b 1
)

goto :rename

:: Function to rename files
:rename
:: Validate the specified directory
if not exist "%folder%" (
    echo Error: The specified directory "%folder%" does not exist.
    exit /b 1
)

:: Navigate to the specified folder
pushd "%folder%" 2>nul
if errorlevel 1 (
    echo Error: Failed to access directory "%folder%".
    exit /b 1
)

:: Check if there are any files to rename
set "fileFound=0"
for %%F in (*.*) do (
    set "fileFound=1"
    goto :countFiles
)

:countFiles
if %fileFound%==0 (
    echo Error: No files found in directory "%folder%".
    popd
    exit /b 1
)

:: Count total files and initialize progress tracking
set /a totalFiles=0
for %%F in (*.*) do set /a "totalFiles+=1"
echo Found %totalFiles% files to process.

if %previewMode%==1 (
    echo Running in preview mode - no files will be changed.
    echo.
)

:: Loop through all files in the directory and rename them
set /a counter=1
set /a processedFiles=0

:: Sort files alphabetically before processing
for /f "tokens=*" %%F in ('dir /b /a-d /o:N *.* 2^>nul') do (
    set "filename=%%F"
    set "ext=%%~xF"
    
    :: Format counter with leading zero if less than 10
    if !counter! lss 10 (
        set "formatted_counter=0!counter!"
    ) else (
        set "formatted_counter=!counter!"
    )
    
    set "newname=%appendString%!formatted_counter!!ext!"
    set /a processedFiles+=1
    
    if %detailMode%==1 (    
        echo [!processedFiles!/%totalFiles%] "!filename!" -^> "!newname!"
    )
    
    if not %previewMode%==1 (
        if %backupMode%==1 (
            if %detailMode%==1 (
                echo Creating backup: "!filename!.bak"
            )
            copy "!filename!" "!filename!.bak" >nul 2>&1
            if errorlevel 1 (
                echo Error: Failed to create backup of "!filename!".
                goto :continue
            )
        )
        
        ren "!filename!" "!newname!" >nul 2>&1
        if errorlevel 1 (
            echo Error: Failed to rename "!filename!" to "!newname!".
        )
    )
    
    :continue
    set /a counter+=1
)

:: Return to the original directory
popd

:: Completion message
if %previewMode%==1 (
    echo Preview completed. No files were renamed.
) else (
    echo Renaming completed successfully! Processed %processedFiles% files.
)
exit /b 0

:: Function to display help message
:help
echo.
echo File Series Renamer - Batch file renaming utility
echo -----------------------------------------------------
echo.
echo Usage: rename-series-names.bat [options]
echo.
echo Options:
echo   -a ^<appendString^>   Set the base name for renaming (e.g., Farzi-S01E)
echo   -d ^<directory^>      Specify the directory to process files (default: current directory)
echo   -p                  Preview mode - show what would be renamed without making changes
echo   -b                  Create backups of files before renaming
echo   --help, -h          Show this help message
echo.
echo Examples:
echo   rename-series-names.bat -a "Farzi-S01E" -d "C:\Movies"
echo   rename-series-names.bat -p -a "Show-S02E"
echo   rename-series-names.bat -b -a "Series-S01E"
echo.
echo Note: Files will be renamed in alphabetical order with numbers padded to 2 digits
exit /b 0