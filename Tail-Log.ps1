function Tail-LogFile {
    <#
    .SYNOPSIS
    Tails a log file, displaying new messages to the console. Optionally, it can exclude lines based on keywords and display lines matching all the specified words.

    .DESCRIPTION
    This function allows you to continuously monitor a log file and display any new log messages that are appended to the file. Additionally, you can exclude specific lines containing certain keywords from the output and display only the lines that contain all the specified words. The function can write the output to a file if the OutFile parameter is specified.

    .PARAMETER Path
    The path of the log file to tail. Maximum length: 260 characters.

    .PARAMETER IntervalSeconds, s
    The interval in seconds between checks for new log messages. Default is 1 second. Maximum length: 10 characters.

    .PARAMETER ExcludeKeywords, x
    An array of keywords to exclude lines containing any of these keywords from the output. Maximum length: 1000 characters.

    .PARAMETER HighlightKeywords, h
    An array of keywords to highlight words containing any of these keywords in the output. Maximum length: 1000 characters.

    .PARAMETER OutFile
    The path to the output file. If specified, the log file will be created in the specified path. If not specified, no log file will be created. Maximum length: 260 characters.

    .PARAMETER LimitKeywords, limit, include, i
    An array of keywords. If specified, only log messages containing any of these keywords will be displayed. Maximum length: 1000 characters.

    .PARAMETER MatchWords, mw
    An array of words. If specified, only log messages containing all of these words will be displayed. Maximum length: 1000 characters.

    .EXAMPLE
    Tail-LogFile -Path 'C:\Logs\app.log' -ExcludeKeywords 'Error', 'Warning'
    Tails the 'C:\Logs\app.log' file, excluding any lines containing the keywords 'Error' or 'Warning'.

    .EXAMPLE
    Tail-LogFile -Path 'C:\Logs\app.log' -OutFile
    Tails the 'C:\Logs\app.log' file and writes the output to the default location (current working directory).

    .EXAMPLE
    Tail-LogFile -Path 'C:\Logs\app.log' -LimitKeywords 'Error', 'Warning' -OutFile 'C:\CustomOutput\error_log_output.txt'
    Tails the 'C:\Logs\app.log' file, displaying only lines containing the keywords 'Error' or 'Warning', and writes the output to the specified custom output file path.

    .EXAMPLE
    Tail-LogFile -Path 'C:\Logs\app.log' -MatchWords 'Error', 'Exception'
    Tails the 'C:\Logs\app.log' file, displaying only lines that contain both 'Error' and 'Exception'.
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
        [string[]]$LimitKeywords,

        [Alias('mw')]
        [ValidateLength(0, 1000)]
        [string[]]$MatchWords
    )

    $filePath = Resolve-Path $Path
    $lastPosition = 0
    $fileStream = $null

    while ($true) {
        # Check if the file exists
        $file = Get-Item $filePath
        if ($file) {
            # Check if the file size has increased
            if ($file.Length -gt $lastPosition) {
                # Check if the file has been renamed or moved (log file rotation)
                if ($fileStream -and $fileStream.Name -ne $filePath) {
                    $fileStream.Dispose()
                    $fileStream = $null
                }

                # Open a new file stream if necessary
                if (-not $fileStream) {
                    $fileStream = [System.IO.File]::Open($filePath, 'Open', 'Read', 'ReadWrite')
                    $fileStream.Position = $lastPosition
                    $reader = New-Object System.IO.StreamReader($fileStream)
                }

                while (!$reader.EndOfStream) {
                    $line = $reader.ReadLine()
                    if ($line -ne $null -and ($ExcludeKeywords -eq $null -or -not (Test-StringContainsAny $line $ExcludeKeywords))) {
                        if ($LimitKeywords -eq $null -or (Test-StringContainsAny $line $LimitKeywords)) {
                            if ($MatchWords -eq $null -or (Test-StringContainsAll $line $MatchWords)) {
                                if ($MatchWords -ne $null) {
                                    $words = $line -split '\s+'
                                    $outputWords = $words[0..6] + " ... " + ($words | Where-Object { $_ -match (Join-ArrayForRegex $MatchWords) })
                                    $line = $outputWords -join ' '
                                }
                                Write-Host $line
                                if ($OutFile) {
                                    Add-Content -Path $OutFile -Value $line
                                }
                            }
                        }
                    }
                }

                $lastPosition = $fileStream.Position
            }
        } else {
            Write-Host "File not found: $Path"
            return
        }

        Start-Sleep -Seconds $IntervalSeconds
    }

    # Close the file stream if it was created
    if ($fileStream) {
        $fileStream.Dispose()
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

function Test-StringContainsAll {
    param (
        [string]$String,
        [string[]]$Keywords
    )

    foreach ($keyword in $Keywords) {
        if ($String -notmatch "(?i)$keyword") {
            return $false
        }
    }
    return $true
}

function Join-ArrayForRegex {
    param (
        [string[]]$Array
    )

    $escapedArray = $Array | ForEach-Object { [regex]::Escape($_) }
    return ($escapedArray -join '|')
}
