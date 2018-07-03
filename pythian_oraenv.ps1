# --------------------------------------------------
# Script pythian_oraenv.ps1
# Created on July 3, 2018
# Author Jose Rodriguez - Pythian
#
# Notes
# This script receives the ORACLE_SID as case sensitive parameter and loads the required environment variables based on the ORACLE_HOME found in the Windows registry

# Get and validate script input parameters
$ORACLE_SID=$args[0]

if ($ORACLE_SID -eq $null) {
Write-Host -ForegroundColor Red "Invalid number of parameters. Usage: pythian_oraenv.ps1 ORACLE_SID" 
exit 1
}


$OHKEY=reg query HKEY_LOCAL_MACHINE\SOFTWARE\Oracle\ /s /e /f $ORACLE_SID /c | Select-String "\\KEY"

if ($OHKEY -eq $null) {
Write-Host -ForegroundColor Red "Oracle SID '$ORACLE_SID' not found in the registry. Please verify SID name and case."
exit 2
}

$OHKEY_VALUE=reg query $OHKEY /V ORACLE_HOME| Select-String REG_SZ
$OHKEY_VALUE= -split $OHKEY_VALUE
$ORACLE_HOME=$OHKEY_VALUE[2] 

$OBASEKEY_VALUE=reg query $OHKEY /V ORACLE_BASE| Select-String REG_SZ
$OBASEKEY_VALUE= -split $OBASEKEY_VALUE
$ORACLE_BASE=$OBASEKEY_VALUE[2]

Write-Host  -ForegroundColor Green "Using $ORACLE_HOME to set the environment variables for database $ORACLE_SID."
Write-Host  -ForegroundColor Green "Setting ORACLE_BASE to $ORACLE_BASE"

$Env:ORACLE_SID=$ORACLE_SID
$Env:ORACLE_HOME=$ORACLE_HOME
$Env:ORACLE_BASE=$ORACLE_BASE
$Env:Path = $Env:Path + ";$ENV:ORACLE_HOME\bin"

