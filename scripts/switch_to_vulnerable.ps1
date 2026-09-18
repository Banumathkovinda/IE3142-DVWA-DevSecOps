# scripts/switch_to_vulnerable.ps1
# Switches the DVWA application source files back to their original vulnerable state (baseline)
# This allows capturing live exploit screenshots for academic evidence.

Write-Host "Reverting application files to vulnerable baseline (commit 076ec69)..." -ForegroundColor Yellow
git checkout 076ec69 -- app/

if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Application is now in VULNERABLE state!" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can now:" -ForegroundColor Cyan
    Write-Host "1. Run exploit test: powershell -ExecutionPolicy Bypass -File scripts/test_exploits_before.ps1"
    Write-Host "2. Visit in browser:"
    Write-Host "   - SQLi: http://127.0.0.1:4280/vulnerabilities/sqli/?id=1%27+OR+%271%27%3D%271&Submit=Submit"
    Write-Host "   - XSS:  http://127.0.0.1:4280/vulnerabilities/xss_r/?name=%3Cscript%3Ealert('XSS-VULNERABLE')%3C%2Fscript%3E"
    Write-Host "   - CMD:  http://127.0.0.1:4280/vulnerabilities/exec/ (Enter: 127.0.0.1; whoami; id)"
    Write-Host "   - CSRF: http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=hacked123&password_conf=hacked123&Change=Change"
    Write-Host ""
    Write-Host "When finished capturing screenshots, restore the secure state by running:" -ForegroundColor Green
    Write-Host "powershell -ExecutionPolicy Bypass -File scripts/switch_to_secure.ps1" -ForegroundColor Green
} else {
    Write-Host "[-] Failed to revert files. Check git status." -ForegroundColor Red
}
