@echo off

:: ****************************************************************************
:: Description: This bat file deletes files created after a specified datetime.
::
:: Usage:		DeleteByCtime /d <directory> /e <extension> /t <timestamp>
::  			  /d  target directory, in the form of a fully qualified path
::  			  /e  target file extension, excluding period
::  			  /t  start timestamp, in format YYYYMMDDHHSS
::
:: Author:		Caleb Gross
:: ****************************************************************************


setlocal EnableDelayedExpansion
set script_name=%~n0
echo.


:::
:: parse command line arguments
:::
:get_args
if [%1] == [] goto :check_args
if [%1] == [/?] goto :usage
if [%1] == [/h] goto :usage
if [%1] == [-h] goto :usage
if [%1] == [/d] set target_directory=%~2
if [%1] == [-d] set target_directory=%~2
if [%1] == [/e] set target_file_extension=%~2
if [%1] == [-e] set target_file_extension=%~2
if [%1] == [/t] set start_timestamp=%~2
if [%1] == [-t] set start_timestamp=%~2
shift & goto :get_args


:::
:: validate runtime arguments
:::
:check_args

:: ensure all arguments passed
if not defined target_directory echo Error: Must define target directory & goto :usage
if not defined target_file_extension echo Error: Must define target file extension goto :usage
if not defined start_timestamp echo Error: Must define start timestamp & goto :usage

:: remove trailing slash in directory
if %target_directory:~-1% == \ set target_directory=%target_directory:~0,-1%

:: remove leading period in filename
if %target_file_extension:~0,1% == ^. set target_file_extension=%target_file_extension:~1%

goto :continue


:::
:: print usage statement and quit
:::
:usage
echo.
echo Usage:
echo .\%script_name% /d [target_directory] /e [target_file_extension] /t [start_timestamp]
echo.
echo - Directory must be a fully qualified path
echo - Do not include a period with the extension
echo - Format datetime YYYYMMDDHHSS
echo.
echo Examples:
echo .\%script_name% /d "C:\temp" /e "txt" /t "201609261500"
echo .\%script_name% /?
goto :eof


:::
:: arguments validated, so proceed with script
:::
:continue

:: regex to check for timestamps in directory listing
set timestamp_regex="^[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]  [0-9][0-9]:[0-9][0-9]"

:: create deleted file counter
set /a deleted_files=0

:: iterate over directory listing entries
for /f "delims=" %%i in (
	'dir /o:d /t:w "!target_directory!\*.!target_file_extension!" ^| findstr /R /C:!timestamp_regex!'
	) do (

	:: get working line of directory listing
	set x=%%i

	:: get target filename
	set filename=!x:~39!

	:: get target datetime string
	set timestamp=!x:~0,20!

	:: convert to 24-hour time
	set hour=!x:~12,2!
	if "!x:~18,2!" == "PM" (set /a hour=!hour!+12)
	if "!x:~17,1!" == "p" (set /a hour=!hour!+12)

	:: generate target create timestamp
	set file_datetime=!x:~6,4!!x:~0,2!!x:~3,2!!hour!!x:~15,2!

	:: check if target file created at or after start time
	if "!file_datetime!" GEQ "!start_timestamp!" (

		:: get full file path
		set full_path="!target_directory!\!filename!"

		:: ask user to affirm file deletion
		echo !timestamp! - !full_path!
		set /p check= "Delete !filename! (Y/n)?"
		if "!check!" == "Y" (

			:: delete file
			del !full_path!

			:: verify file deletion
			set /p "=Verifying..." <nul
			if exist !full_path! (

				:: if file still exists, print error
				echo Could not delete file. Check your permissions.

			) else (

				:: otherwise, increment counter and print success
				set /a deleted_files+=1
				echo !filename! successfully deleted.
			)
		)

		:: print blank line for terminal readability
		echo.
	)
)

:: print summary of deleted files
echo !deleted_files! files deleted.