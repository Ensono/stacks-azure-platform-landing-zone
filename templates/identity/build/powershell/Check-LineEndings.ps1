$checkFailed = $false

# Define binary file extensions to exclude from line ending checks
$binaryExtensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.ico', '.pdf', '.zip', '.tar', '.gz', '.exe', '.dll', '.so', '.dylib', '.bin', '.dat', '.db', '.sqlite', '.woff', '.woff2', '.ttf', '.eot', '.svg', '.mp4', '.avi', '.mov', '.mp3', '.wav', '.flac')

Get-ChildItem -Recurse -File | Where-Object {
    -not $_.FullName.Contains('\.git\') -and
    -not $_.FullName.Contains('\.terraform\') -and
    -not $_.FullName.Contains('\tfplan') -and
    -not $_.FullName.Contains('\terraform.tfstate') -and
    -not ($binaryExtensions -contains $_.Extension.ToLower())
} | ForEach-Object {
    try {
        $content = Get-Content $_.FullName -Raw -ErrorAction Stop
        if ($content -match "`r`n") {
            Write-Host "CRLF line endings detected in $($_.FullName)"
            $checkFailed = $true
        }
    }
    catch {
        # Skip files that can't be read as text (likely binary files)
        Write-Verbose "Skipping binary file: $($_.FullName)"
    }
}

$InformationPreference = "Continue"
$ErrorActionPreference = "Stop"

if ($checkFailed) {
    Write-Error "CRLF line endings detected. Please use LF only."
    exit 1
}
else {
    Write-Information -MessageData ("No '{0}'endings found" -f "CRLF")
}
