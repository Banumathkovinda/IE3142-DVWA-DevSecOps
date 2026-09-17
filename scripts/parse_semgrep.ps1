# Parse Semgrep baseline findings
param (
    [string]$FilePath = "security/semgrep/semgrep-baseline.json"
)

if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

$data = Get-Content $FilePath -Raw | ConvertFrom-Json
Write-Host "Total findings in codebase: $($data.results.Count)"
Write-Host "--------------------------------------------------------"

$targetModules = @(
    "vulnerabilities/sqli/source/low.php",
    "vulnerabilities/xss_r/source/low.php",
    "vulnerabilities/exec/source/low.php",
    "vulnerabilities/csrf/source/low.php"
)

$targetFindings = $data.results | Where-Object {
    $p = $_.path.Replace('\', '/')
    foreach ($m in $targetModules) {
        if ($p -like "*$m*") { return $true }
    }
    return $false
}

Write-Host "Findings in 4 target low.php modules: $($targetFindings.Count)"
Write-Host "--------------------------------------------------------"
foreach ($finding in $targetFindings) {
    Write-Host "Rule ID  : $($finding.check_id)"
    Write-Host "File     : $($finding.path)"
    Write-Host "Line     : $($finding.start.line)"
    Write-Host "Severity : $($finding.extra.severity)"
    Write-Host "Message  : $($finding.extra.message)"
    Write-Host "Snippet  : $($finding.extra.lines.Trim())"
    Write-Host "--------------------------------------------------------"
}
