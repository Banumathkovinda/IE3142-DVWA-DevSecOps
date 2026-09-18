# scripts/rename_screenshots.ps1
# Automates renaming captured Windows screenshots to official evidence filenames

$renames = @(
    @{ Path = "evidence/01-original-dvwa/Screenshot 2026-09-18 044013.png"; NewName = "03-dvwa-logged-in-index.png" },
    @{ Path = "evidence/02-sqli-before/Screenshot 2026-09-18 044247.png"; NewName = "sqli-before-burp-or-terminal.png" },
    @{ Path = "evidence/03-sqli-after/Screenshot 2026-09-18 044349.png"; NewName = "sqli-after-blocked-browser.png" },
    @{ Path = "evidence/03-sqli-after/Screenshot 2026-09-18 044513.png"; NewName = "sqli-after-legitimate-browser.png" },
    @{ Path = "evidence/04-xss-before/Screenshot 2026-09-18 044635.png"; NewName = "xss-before-popup.png" },
    @{ Path = "evidence/05-xss-after/Screenshot 2026-09-18 044748.png"; NewName = "xss-after-browser.png" },
    @{ Path = "evidence/05-xss-after/Screenshot 2026-09-18 054739.png"; NewName = "xss-after-source.png" },
    @{ Path = "evidence/06-command-injection-before/Screenshot 2026-09-18 045119.png"; NewName = "cmd-injection-before-browser.png" },
    @{ Path = "evidence/07-command-injection-after/Screenshot 2026-09-18 045336.png"; NewName = "cmd-after-blocked-browser.png" },
    @{ Path = "evidence/07-command-injection-after/Screenshot 2026-09-18 045428.png"; NewName = "cmd-after-ping-browser.png" },
    @{ Path = "evidence/08-csrf-before/Screenshot 2026-09-18 045532.png"; NewName = "csrf-before-browser.png" },
    @{ Path = "evidence/09-csrf-after/Screenshot 2026-09-18 050824.png"; NewName = "csrf-after-blocked-browser.png" },
    @{ Path = "evidence/09-csrf-after/Screenshot 2026-09-18 051306.png"; NewName = "csrf-after-legitimate-browser.png" },
    @{ Path = "evidence/10-sast-before/Screenshot 2026-09-18 051936.png"; NewName = "semgrep-baseline-terminal.png" },
    @{ Path = "evidence/11-sast-after/Screenshot 2026-09-18 052012.png"; NewName = "semgrep-after-terminal.png" },
    @{ Path = "evidence/12-dependency-scan/Screenshot 2026-09-18 052157.png"; NewName = "trivy-fs-scan-terminal.png" },
    @{ Path = "evidence/12-dependency-scan/composer audit/Screenshot 2026-09-18 052233.png"; TargetPath = "evidence/12-dependency-scan/composer-audit-terminal.png" },
    @{ Path = "evidence/13-gitleaks/Screenshot 2026-09-18 052335.png"; NewName = "gitleaks-scan-clean-terminal.png" },
    @{ Path = "evidence/14-trivy/Screenshot 2026-09-18 052612.png"; NewName = "trivy-image-scan-terminal.png" },
    @{ Path = "evidence/14-trivy/Screenshot 2026-09-18 052643.png"; NewName = "trivy-clean-packages.png" }
)

Write-Host "Starting evidence screenshot standardization..." -ForegroundColor Cyan

foreach ($item in $renames) {
    if (Test-Path $item.Path) {
        if ($item.TargetPath) {
            $destDir = Split-Path $item.TargetPath -Parent
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Move-Item -Path $item.Path -Destination $item.TargetPath -Force
            Write-Host "Moved & Renamed: $($item.Path) -> $($item.TargetPath)" -ForegroundColor Green
        } else {
            Rename-Item -Path $item.Path -NewName $item.NewName -Force
            Write-Host "Renamed: $($item.Path) -> $($item.NewName)" -ForegroundColor Green
        }
    } else {
        Write-Host "Skipped (already renamed or missing): $($item.Path)" -ForegroundColor Gray
    }
}

# Clean up empty 'composer audit' subdirectory if left over
$subDir = "evidence/12-dependency-scan/composer audit"
if ((Test-Path $subDir) -and ((Get-ChildItem $subDir).Count -eq 0)) {
    Remove-Item -Path $subDir -Force -Recurse
    Write-Host "Cleaned up temporary subdirectory: $subDir" -ForegroundColor Yellow
}

Write-Host "Standardization complete!" -ForegroundColor Cyan
