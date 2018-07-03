# --------------------------------------------------
# Script rman_backups.ps1
# Created on Jun 27, 2018
# Author Jose Rodriguez - Pythian
#
# Notes
# This script has to be executed by a user that is member of the ora_dba user group.
# The script uses additional SID specific RMAN script files for each backup type: FULL, INCR and ARCH.
# The script name format must be "backup-<ORACLE_SID>-<RMAN_TYPE>.rmn" and it must be a RMAN valid script.
# A log file will be created on each execution with a timestamp mark in the name.


# Get and validate script input parameters
$ORACLE_SID=$args[0]
$RMAN_TYPE=$args[1]

$SCRIPT_NAME=$MyInvocation.MyCommand.Name

if ($ORACLE_SID -eq $null -or $RMAN_TYPE -eq $null) {
Write-Host -ForegroundColor Red "Invalid number of parameters. Usage: $SCRIPT_NAME ORACLE_SID RMAN_TYPE"
exit 5
}

if ($RMAN_TYPE -ne "FULL" -and $RMAN_TYPE -ne "INCR" -and $RMAN_TYPE -ne "ARCH") {
Write-Host -ForegroundColor Red "Invalid RMAN_TYPE. Must be either one of FULL, INCR or ARCH."
exit 4
}

$datetime =  Get-Date -Format "yyyyMMdd-hhmm"

# Constants
$BIN_DIR=Split-Path $MyInvocation.MyCommand.path
$LOG_DIR="$BIN_DIR\logs"
$RMAN_LOG="$LOG_DIR\backup_"+$RMAN_TYPE+"_"+$ORACLE_SID+"_"+$datetime+".log"

# Verify log dir existence and create it if not there
if(!(Test-Path -Path $LOG_DIR )){
    New-Item -ItemType directory -Path $LOG_DIR
}

# Loading Oracle environment variables
$OHKEY=reg query HKEY_LOCAL_MACHINE\SOFTWARE\Oracle\ /s /e /f $ORACLE_SID /c | Select-String "\\KEY"

if ($OHKEY -eq $null) {
Write-Output "Oracle SID '$ORACLE_SID' not found in the registry. Please verify SID name and case." >> $RMAN_LOG
exit 3
}

$OHKEY_VALUE=reg query $OHKEY /V ORACLE_HOME| Select-String REG_SZ
$OHKEY_VALUE= -split $OHKEY_VALUE
$ORACLE_HOME=$OHKEY_VALUE[2] 

$OBASEKEY_VALUE=reg query $OHKEY /V ORACLE_BASE| Select-String REG_SZ
$OBASEKEY_VALUE= -split $OBASEKEY_VALUE
$ORACLE_BASE=$OBASEKEY_VALUE[2]

Write-Output "Using $ORACLE_HOME to set the environment variables for database $ORACLE_SID."  >> $RMAN_LOG
Write-Output "Setting ORACLE_BASE to $ORACLE_BASE"  >> $RMAN_LOG

$Env:ORACLE_SID=$ORACLE_SID
$Env:ORACLE_HOME=$ORACLE_HOME
$Env:ORACLE_BASE=$ORACLE_BASE
$Env:Path = $Env:Path + ";$ENV:ORACLE_HOME\bin"

# Staring the RMAN command
$Env:NLS_DATE_FORMAT='dd-mm-yyyy hh24:mi:ss'

#call rman to run the backup script and output to log file
$RMAN_SCRIPT=$BIN_DIR+"\backup_"+$ORACLE_SID+"_"+$RMAN_TYPE+".rmn"


if(!(Test-Path -Path $RMAN_SCRIPT )){
    Write-Output "ERROR: RMAN script not found for database $($ORACLE_SID) and backup type $($RMAN_TYPE)" >> $RMAN_LOG
    Write-Output "Failed backup $($RMAN_TYPE) for $($ORACLE_SID) @ $($datetime)" >> $RMAN_LOG
    exit 2
}

rman target / nocatalog cmdfile="$RMAN_SCRIPT" >> $RMAN_LOG

#get completion date and time
$datetime = Get-Date
$RMAN_ERROR = Select-String -Pattern "ORA-|RMAN-" -LiteralPath $RMAN_LOG -Quiet
if ($RMAN_ERROR -eq $True) {
    Write-Output ("Failed backup $($RMAN_TYPE) for $($ORACLE_SID) @ $($datetime)") >> $RMAN_LOG
    exit 1
}
else {
 Write-Output ("Successful completion of $($RMAN_TYPE) for $($ORACLE_SID) @ $($datetime)") >> $RMAN_LOG
}

exit
