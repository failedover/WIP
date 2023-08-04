function Tail-LogFile {
    <#
    .SYNOPSIS
    Tails a log file, displaying new messages to the console. Optionally, it can exclude or highlight lines based on keywords.

    .DESCRIPTION
    This function allows you to continuously monitor a log file and display any new log messages that are appended to the file. Additionally, you can exclude specific lines containing certain keywords from the output and highlight lines that contain specific keywords. The function can write the output to a file if the OutFile parameter is specified.

    .PARAMETER Path
    The path of the log file to tail. Maximum length: 260 characters.

    .PARAMETER IntervalSeconds, s
    The interval in seconds between checks for new log messages. Default is 1 second. Maximum length: 10 characters.

    .PARAMETER ExcludeKeywords, x
    An array of keywords to exclude lines containing any of these keywords from the output. Maximum length: 1000 characters.

    .PARAMETER HighlightKeywords, h
    An array of keywords to highlight lines containing any of these keywords in the output. Maximum length: 1000 characters.

    .PARAMETER OutFile
    The path to the output file. If specified, the log file will be created in the specified path. If not specified, no log file will be created. Maximum length: 260 characters.

    .PARAMETER LimitKeywords, limit, include, i
    An array of keywords. If specified, only log messages containing any of these keywords will be displayed. Maximum length: 1000 characters.

    .EXAMPLE
    Tail-LogFile -Path 'C:\Logs\app.log' -ExcludeKeywords 'Error', 'Warning'
    Tails the 'C:\Logs\app.log' file, excluding any lines containing the keywords 'Error' or 'Warning'.

    .EXAMPLE
    Tail-LogFile -Path 'C:\Logs\app.log' -HighlightKeywords 'Success', 'Important' -OutFile
    Tails the 'C:\Logs\app.log' file, highlighting any lines containing the keywords 'Success' or 'Important', and writes the output to the default location (current working directory).

    .EXAMPLE
    Tail-LogFile -Path 'C:\Logs\app.log' -LimitKeywords 'Error', 'Warning' -OutFile 'C:\CustomOutput\error_log_output.txt'
    Tails the 'C:\Logs\app.log' file, displaying only lines containing the keywords 'Error' or 'Warning', and writes the output to the specified custom output file path.
    #>

    param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateLength(0, 260)]
        [string]$Path,

        [Alias('s')]
        [int]$IntervalSeconds = 1,

        [Alias('exclude', 'x')]
        [ValidateLength(0, 1000)]
        [string[]]$ExcludeKeywords,

        [Alias('highlight', 'h')]
        [ValidateLength(0, 1000)]
        [string[]]$HighlightKeywords,

        [ValidateLength(0, 260)]
        [string]$OutFile,

        [Alias('limit', 'include', 'i')]
        [ValidateLength(0, 1000)]
        [string[]]$LimitKeywords
    )

    if ($OutFile) {
        if (-not $OutFile -or $OutFile -eq $true) {
            # If OutFile is specified without a value or with a value of $true, use the default path in the current working directory
            $OutFile = Join-Path (Get-Location) ("log_output_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".txt")
        } else {
            # Check if the specified path is a folder, if yes, create the log file in that folder
            if ((Test-Path $OutFile) -and (Get-Item $OutFile).PSIsContainer) {
                $OutFile = Join-Path $OutFile ("log_output_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + ".txt")
            } else {
                # If OutFile is a full file path, use it as is
                $OutFile = $OutFile
            }
        }

        $outputFile = [System.IO.File]::Open($OutFile, 'Append', 'Write', 'ReadWrite')
    }

    $filePath = Resolve-Path $Path
    $lastPosition = 0

    while ($true) {
        $file = Get-Item $filePath

        # Check if the file exists
        if ($file) {
            # Check if the file size has increased
            if ($file.Length -gt $lastPosition) {
                $fileStream = [System.IO.File]::Open($filePath, 'Open', 'Read', 'ReadWrite')
                $fileStream.Position = $lastPosition
                $reader = New-Object System.IO.StreamReader($fileStream)

                while (!$reader.EndOfStream) {
                    $line = $reader.ReadLine()
                    if ($line -ne $null -and ($ExcludeKeywords -eq $null -or -not (Test-StringContainsAny $line $ExcludeKeywords))) {
                        if ($LimitKeywords -eq $null -or (Test-StringContainsAny $line $LimitKeywords)) {
                            if ($HighlightKeywords -ne $null -and (Test-StringContainsAny $line $HighlightKeywords)) {
                                Write-Host $line -ForegroundColor Yellow
                            } else {
                                Write-Host $line
                            }

                            if ($OutFile) {
                                Add-Content -Path $OutFile -Value $line
                            }
                        }
                    }
                }

                $lastPosition = $fileStream.Position
                $reader.Close()
                $fileStream.Close()
            }
        } else {
            Write-Host "File not found: $Path"
            return
        }

        Start-Sleep -Seconds $IntervalSeconds
    }

    # Close the output file if it was created
    if ($OutFile) {
        $outputFile.Close()
    }
}

function Test-StringContainsAny {
    param (
        [string]$String,
        [string[]]$Keywords
    )

    foreach ($keyword in $Keywords) {
        if ($String.Contains($keyword)) {
            return $true
        }
    }
    return $false
}