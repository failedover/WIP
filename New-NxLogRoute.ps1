Function New-NxLogRoute
{
    <#
    .DESCRIPTION
    Creates a new NxLog Route String.  Can accept multiple inputs and ouputs
    .PARAMETER RouteName
    Name of the Route
    .PARAMETER InputNames
    Array of Input Names
    .PARAMETER OutputNames
    Array of Output Names
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$RouteName,
        [Parameter(Mandatory=$true)]
        [string[]]$InputNames,
        [Parameter(Mandatory=$true)]
        [string[]]$OutputNames
    )
    Process
    {
        $NxLogRouteString = "<Route $RouteName>"
        $NxLogRouteString += "`n    Path "
        $NxLogRouteString += $InputNames -join ","
        $NxLogRouteString += " => "
        $NxLogRouteString += $OutputNames -join ","
        $NxLogRouteString += "`n</Route>"
    }
    End
    {
        Return $NxLogRouteString
    }
}