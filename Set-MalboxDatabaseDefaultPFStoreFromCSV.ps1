<#
.SYNOPSIS
    Quick description of this script

.DESCRIPTION
    Longer description of what this script does

.PARAMETER FirstNumber
    This parameter does blablabla

.PARAMETER CheckVersion
    This parameter will just dump the script current version.

.INPUTS
    None. You cannot pipe objects to that script.

.OUTPUTS
    None for now

.EXAMPLE
.\Do-Something.ps1
This will launch the script and do someting

.EXAMPLE
.\Do-Something.ps1 -CheckVersion
This will dump the script name and current version like :
SCRIPT NAME : Do-Something.ps1
VERSION : v1.0

.NOTES
None

.LINK
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-6

.LINK
    https://github.com/SammyKrosoft
#>
[CmdLetBinding(DefaultParameterSetName = "NormalRun")]
Param(
    [Parameter(Mandatory = $False, Position = 1, ParameterSetName = "NormalRun")][string]$InputCSV = ".\MAilboxDatabases-DefaultPublicStore.csv",
    [Parameter(Mandatory = $False, Position = 2, ParameterSetName = "NormalRun")][switch]$TestOnly,
    [Parameter(Mandatory = $false, Position = 3, ParameterSetName = "CheckOnly")][switch]$CheckVersion
)

<# ------- SCRIPT_HEADER (Only Get-Help comments and Param() above this point) ------- #>
#Initializing a $Stopwatch variable to use to measure script execution
$stopwatch = [system.diagnostics.stopwatch]::StartNew()
#Using Write-Debug and playing with $DebugPreference -> "Continue" will output whatever you put on Write-Debug "Your text/values"
# and "SilentlyContinue" will output nothing on Write-Debug "Your text/values"
$DebugPreference = "Continue"
# Set Error Action to your needs
$ErrorActionPreference = "Stop"
#Script Version
$ScriptVersion = "0.1"
<# Version changes
v0.1 : first script version
v0.1 -> v0.5 : 
#>
$ScriptName = $MyInvocation.MyCommand.Name
If ($CheckVersion) {Write-Host "SCRIPT NAME     : $ScriptName `nSCRIPT VERSION  : $ScriptVersion";exit}
# Log or report file definition
# NOTE: use $PSScriptRoot in Powershell 3.0 and later or use $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition in Powershell 2.0
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$OutputReport = "$ScriptPath\$($ScriptName)_$(get-date -f yyyy-MM-dd-hh-mm-ss).csv"
# Other Option for Log or report file definition (use one of these)
$ScriptLog = "$ScriptPath\$($ScriptName)-$(Get-Date -Format 'dd-MMMM-yyyy-hh-mm-ss-tt').txt"
<# ---------------------------- /SCRIPT_HEADER ---------------------------- #>
<# -------------------------- DECLARATIONS -------------------------- #>

<# /DECLARATIONS #>
<# -------------------------- FUNCTIONS -------------------------- #>
Function HereStringToArray ($HereString) {
    Return $HereString -split "`n" | %{$_.trim()}
}

Function Test-ExchTools(){
    <#
    .SYNOPSIS
    This small function will just check if you have Exchange tools installed or available on the
    current PowerShell session.
    
    .DESCRIPTION
    The presence of Exchange tools are checked by trying to execute "Get-ExBanner", one of the basic Exchange
    cmdlets that runs when the Exchange Management Shell is called.
    
    Just use Test-ExchTools in your script to make the script exit if not launched from an Exchange
    tools PowerShell session...
    
    .EXAMPLE
    Test-ExchTools
    => will exit the script/program si Exchange tools are not installed
    #>
        Try
        {
            #Get-command Get-ExBanner -ErrorAction Stop
            Get-command Get-Mailbox -ErrorAction Stop
            $ExchInstalledStatus = $true
            $Message = "Exchange tools are present !"
            Write-Host $Message -ForegroundColor Blue -BackgroundColor Red
        }
        Catch [System.SystemException]
        {
            $ExchInstalledStatus = $false
            $Message = "Exchange Tools are not present ! This script/tool need these. Exiting..."
            Write-Host $Message -ForegroundColor red -BackgroundColor Blue
            Exit
        }
        Return $ExchInstalledStatus
    }

function import-ValidCSV {
    <#
    .SYNOPSIS
        Imports a CSV file, validating that it has the columns specified in the -requiredColumns parameter.
        Throws a critical error if a required column is not found.

    .NOTES
        IMPORTANT INFORMATION:
        Please always mention the original authors of scripts or script extracts, it helps for traceability, and
        more importantly gives back to Caesar what belong to Caesar ;-)
        
            Author : Jason Coleman
            Role: Californian PowerShell and Virtualization Genius
            Link: https://virtuallyjason.blogspot.com/2016/08/import-validcsv-powershell-function.html

    .LINK
        https://virtuallyjason.blogspot.com/2016/08/import-validcsv-powershell-function.html
    #>

    param
        (
                [parameter(Mandatory=$true)]
                [ValidateScript({test-path $_ -type leaf})]
                [string]$inputFile,
                [string[]]$requiredColumns
        )
        $csvImport = import-csv $inputFile
        $inputTest = $csvImport | gm
        foreach ($requiredColumn in $requiredColumns)
        {
                if (!($inputTest | ? {$_.name -eq $requiredColumn}))
                {
                        write-error "$inputFile is missing the $requiredColumn column"
                        exit 10
                }
        }
        $csvImport
}
<# /FUNCTIONS #>
<# -------------------------- EXECUTIONS -------------------------- #>
If (!$TestOnly){
    #Test-ExchTools
}

$requiredColumns = @"
Name
PublicFolderDatabase
"@

$Columns = HereStringToArray $requiredColumns

$MailboxDatabaseAndDefaultPFTable = import-ValidCSV -inputFile $InputCSV -requiredColumns $Columns

Foreach ($Item in $MailboxDatabaseAndDefaultPFTable) {
    $DatabaseFirst2Letters = $Item.Name.Substring(0,2)

    $cmd = "Set-MailboxDatabase $($Item.Name) -PublicFolderDatabase $($Item.PublicFolderDatabase)"
    If ($TestOnly){
        Write-host $cmd
    } Else {
        Write-Host "$(Get-Date -F "dd-MM-yyyy@hh-mm-ss") # Executing $cmd ..."
        Invoke-Expression $cmd
    }
}

<# /EXECUTIONS #>
<# -------------------------- CLEANUP VARIABLES -------------------------- #>

<# /CLEANUP VARIABLES#>
<# ---------------------------- SCRIPT_FOOTER ---------------------------- #>
#Stopping StopWatch and report total elapsed time (TotalSeconds, TotalMilliseconds, TotalMinutes, etc...
$stopwatch.Stop()
$msg = "`n`nThe script took $([math]::round($($StopWatch.Elapsed.TotalSeconds),2)) seconds to execute..."
Write-Host $msg
$msg = $null
$StopWatch = $null
<# ---------------- /SCRIPT_FOOTER (NOTHING BEYOND THIS POINT) ----------- #>
