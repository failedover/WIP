Function New-NxLogImFile
{
    <#
    .DESCRIPTION
    Creates new input for nxlog to be used later
    .PARAMETER InputName
    Name of the IMFile Input
    .PARAMETER File
    Path to file to be read
    .PARAMETER SavePos
    Whether to save position (TRUE or FALSE)
    .PARAMETER ReadFromLast
    Whether to read from last position (TRUE or FALSE)
    .PARAMETER Recursive
    Whether to read recursively (TRUE or FALSE)
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$InputName,
        [Parameter(Mandatory=$true)]
        [string]$File,
        [Parameter(Mandatory=$false)]
        [bool]$SavePos = $true,
        [Parameter(Mandatory=$false)]
        [bool]$ReadFromLast = $true,
        [Parameter(Mandatory=$false)]
        [bool]$Recursive = $true
    )

    Process
    {
    $NxLogImString ="<Input $InputName>"
    $NxLogImString += "`n    Module im_file"
    $NxLogImString += "`n    File '$File'"
    $NxLogImString += "`n    SavePos $SavePos"
    $NxLogImString += "`n    ReadFromLast $ReadFromLast"
    $NxLogImString += "`n    Recursive $Recursive"
    $NxLogImString += "`n</Input>"
    }
    End
    {
        Return $NxLogImString
    }
}