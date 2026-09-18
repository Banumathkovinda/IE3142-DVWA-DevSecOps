# scripts/switch_to_secure.ps1
# Restores the DVWA application source files back to their remediated, secure state (HEAD)

Write-Host "Restoring application files to remediated secure state (HEAD)..." -ForegroundColor Cyan
git checkout HEAD -- app/

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Application is now restored to SECURE state!" -ForegroundColor Green
    Write-Host "All prepared statements, input whitelisting, output encoding, and anti-CSRF protections are active." -ForegroundColor Gray
} else {
    Write-Host "[-] Failed to restore files. Check git status." -ForegroundColor Red
}
