@echo off

rem Script to generate ReFS test files
rem Requires Windows Server

rem Split the output of ver e.g. "Microsoft Windows [Version 10.0.10586]"
rem and keep the last part "10.0.10586]".
for /f "tokens=1,2,3,4" %%a in ('ver') do (
	set version=%%d
)

rem Replace dots by spaces "10 0 10586]".
set version=%version:.= %

rem Split the last part of the ver output "10 0 10586]" and keep the first
rem 2 values formatted with a dot as separator "10.0".
for /f "tokens=1,2,*" %%a in ("%version%") do (
	set version=%%a.%%b
)

set specimenspath=specimens\%version%

if exist "%specimenspath%" (
	echo Specimens directory: %specimenspath% already exists.

	exit /b 1
)

mkdir "%specimenspath%"

rem Create a variable-size VHD image with a ReFS file system with 64k unitsize
set unitsize=65536
set imagename=refs_64k.vhd
rem Windows server 2012 supports 1024 (1 GiB) imagesize but this is too small for Windows server 2019
set imagesize=2048

echo create vdisk file=%cd%\%specimenspath%\%imagename% maximum=%imagesize% type=expandable > CreateVHD.diskpart
echo select vdisk file=%cd%\%specimenspath%\%imagename% >> CreateVHD.diskpart
echo attach vdisk >> CreateVHD.diskpart
echo convert gpt >> CreateVHD.diskpart
echo create partition primary >> CreateVHD.diskpart

echo format fs=refs label="TestVolume" unit=%unitsize% quick >> CreateVHD.diskpart

echo assign letter=x >> CreateVHD.diskpart

call :run_diskpart CreateVHD.diskpart

call :create_test_file_entries x

echo select vdisk file=%cd%\%specimenspath%\%imagename% > UnmountVHD.diskpart
echo detach vdisk >> UnmountVHD.diskpart

call :run_diskpart UnmountVHD.diskpart

rem Create a variable-size VHD image with a ReFS file system with 4k unitsize
set unitsize=4096
set imagename=refs_4k.vhd

if "%version%" == "10.0" (
	echo create vdisk file=%cd%\%specimenspath%\%imagename% maximum=%imagesize% type=expandable > CreateVHD.diskpart
	echo select vdisk file=%cd%\%specimenspath%\%imagename% >> CreateVHD.diskpart
	echo attach vdisk >> CreateVHD.diskpart
	echo convert gpt >> CreateVHD.diskpart
	echo create partition primary >> CreateVHD.diskpart

	echo format fs=refs label="TestVolume" unit=%unitsize% quick >> CreateVHD.diskpart

	echo assign letter=x >> CreateVHD.diskpart

	call :run_diskpart CreateVHD.diskpart

	call :create_test_file_entries x

	echo select vdisk file=%cd%\%specimenspath%\%imagename% > UnmountVHD.diskpart
	echo detach vdisk >> UnmountVHD.diskpart

	call :run_diskpart UnmountVHD.diskpart
)

rem Create a ReFS file system with default unitsize and 100 files
set imagename=refs_100_files.vhd

echo create vdisk file=%cd%\%specimenspath%\%imagename% maximum=%imagesize% type=expandable > CreateVHD.diskpart
echo select vdisk file=%cd%\%specimenspath%\%imagename% >> CreateVHD.diskpart
echo attach vdisk >> CreateVHD.diskpart
echo convert gpt >> CreateVHD.diskpart
echo create partition primary >> CreateVHD.diskpart

echo format fs=refs label="TestVolume" quick >> CreateVHD.diskpart

echo assign letter=x >> CreateVHD.diskpart

call :run_diskpart CreateVHD.diskpart

call :create_many_test_files x 100

echo select vdisk file=%cd%\%specimenspath%\%imagename% > UnmountVHD.diskpart
echo detach vdisk >> UnmountVHD.diskpart

call :run_diskpart UnmountVHD.diskpart

rem Create a ReFS file system with default unitsize and a file with 100 alternative data streams (ADS)
set imagename=refs_100_ads.vhd

echo create vdisk file=%cd%\%specimenspath%\%imagename% maximum=%imagesize% type=expandable > CreateVHD.diskpart
echo select vdisk file=%cd%\%specimenspath%\%imagename% >> CreateVHD.diskpart
echo attach vdisk >> CreateVHD.diskpart
echo convert gpt >> CreateVHD.diskpart
echo create partition primary >> CreateVHD.diskpart

echo format fs=refs label="TestVolume" quick >> CreateVHD.diskpart

echo assign letter=x >> CreateVHD.diskpart

call :run_diskpart CreateVHD.diskpart

call :create_many_test_data_streams x 100

echo select vdisk file=%cd%\%specimenspath%\%imagename% > UnmountVHD.diskpart
echo detach vdisk >> UnmountVHD.diskpart

call :run_diskpart UnmountVHD.diskpart

exit /b 0

rem Creates many test data_streams
:create_many_test_data_streams
SETLOCAL
SET driveletter=%1
SET totalnumber=%2

call :create_test_file_entries %driveletter%

type nul >> %driveletter%:\file_ads2

for /l %%a in (1, 1, %totalnumber%) do (
	echo More ADS %%a > %driveletter%:\file_ads2:ads%%a
)

ENDLOCAL
exit /b 0

rem Creates many test files
:create_many_test_files
SETLOCAL
SET driveletter=%1
SET totalnumber=%2

call :create_test_file_entries %driveletter%

for /l %%a in (3, 1, %totalnumber%) do (
	type nul >> %driveletter%:\testdir1\testfile%%a
)

ENDLOCAL
exit /b 0

rem Creates test file entries
:create_test_file_entries
SETLOCAL
SET driveletter=%1

rem Create an emtpy file
type nul >> %driveletter%:\emptyfile

rem Create a directory
mkdir %driveletter%:\testdir1

rem Create a file that contains a small amount of data
echo My file > %driveletter%:\testdir1\testfile1

rem Create a file that contains a larger amount of data
copy LICENSE %driveletter%:\testdir1\testfile2

rem Create a file with a long filename
type nul >> "%driveletter%:\My long, very long file name, so very long"

rem Create a hard link to a file
mklink /H %driveletter%:\file_hardlink1 %driveletter%:\testdir1\testfile1

rem Create a symbolic link to a file
mklink %driveletter%:\file_symboliclink1 %driveletter%:\testdir1\testfile1

rem Create a junction (hard link to a directory)
mklink /J %driveletter%:\directory_junction1 %driveletter%:\testdir1

rem Create a symbolic link to a directory
mklink /D %driveletter%:\directory_symboliclink1 %driveletter%:\testdir1

rem Create a file with an alternative data stream (ADS)
type nul >> %driveletter%:\file_ads1
echo My file ADS > %driveletter%:\file_ads1:myads

rem Create a directory with an alternative data stream (ADS)
mkdir %driveletter%:\directory_ads1
echo My directory ADS > %driveletter%:\directory_ads1:myads

rem Create a file with valid data size set
copy LICENSE %driveletter%:\testdir1\file_valid_data_size1
fsutil file setValidData %driveletter%:\testdir1\file_valid_data_size1 18652

rem Create a file with short name set
echo My short file > %driveletter%:\testdir1\file_short_name1
fsutil file setShortName %driveletter%:\testdir1\file_short_name1 short1

rem Create a file with a sparse data run
copy LICENSE %driveletter%:\testdir1\file_sparse1
fsutil sparse setflag %driveletter%:\testdir1\file_sparse1
fsutil sparse setRange %driveletter%:\testdir1\file_sparse1 0 18000

rem TODO: add test case that sets a sparse extent
rem fsutil file setZeroData

rem TODO: add test case that sets an object identifier
rem fsutil objectid set

ENDLOCAL
exit /b 0

rem Runs diskpart with a script
rem Note that diskpart requires Administrator privileges to run
:run_diskpart
SETLOCAL
set diskpartscript=%1

rem Note that diskpart requires Administrator privileges to run
diskpart /s %diskpartscript%

if %errorlevel% neq 0 (
	echo Failed to run: "diskpart /s %diskpartscript%"

	exit /b 1
)

del /q %diskpartscript%

rem Give the system a bit of time to adjust
timeout /t 1 > nul

ENDLOCAL
exit /b 0

