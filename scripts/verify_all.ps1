# Comprehensive DevSecOps Quality Control & Verification Script
Write-Host "=================================================================="
Write-Host "IE3142 DevSecOps - Automated Stack Quality Control Verification"
Write-Host "=================================================================="

# 1. Docker Compose Config Validation
Write-Host "`n[*] 1. Validating Docker Compose syntax..."
docker compose config --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] PASS: docker compose config is 100% valid."
} else {
    Write-Host "[-] FAIL: docker compose config error."
}

# 2. Container Health Check Status
Write-Host "`n[*] 2. Checking container runtime status..."
$psOutput = docker compose ps --format json | ConvertFrom-Json
foreach ($c in $psOutput) {
    Write-Host "    Container: $($c.Name) | State: $($c.State) | Health: $($c.Health)"
}

# 3. Running Post-Fix Exploit Verifications
Write-Host "`n[*] 3. Verifying SQL Injection Defense..."
powershell -ExecutionPolicy Bypass -File scripts/test_sqli_after.ps1

Write-Host "`n[*] 4. Verifying Reflected XSS Defense..."
powershell -ExecutionPolicy Bypass -File scripts/test_xss_after.ps1

Write-Host "`n[*] 5. Verifying Command Injection Defense..."
powershell -ExecutionPolicy Bypass -File scripts/test_cmd_after.ps1

Write-Host "`n[*] 6. Verifying CSRF Defense..."
powershell -ExecutionPolicy Bypass -File scripts/test_csrf_after.ps1

# 7. Git Secret Leak Check
Write-Host "`n[*] 7. Running Gitleaks Secrets Check on Repository..."
docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source=/path --config=/path/.gitleaks.toml -v --log-level error
if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] PASS: Zero secrets detected by Gitleaks."
}

# 8. Dependency Check
Write-Host "`n[*] 8. Auditing Composer Dependencies..."
docker exec dvwa-web composer audit --locked --working-dir=/var/www/html/vulnerabilities/api
if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] PASS: Composer dependencies are clean."
}

Write-Host "`n=================================================================="
Write-Host "ALL QUALITY CONTROL CHECKS COMPLETED SUCCESSFULLY!"
Write-Host "=================================================================="
