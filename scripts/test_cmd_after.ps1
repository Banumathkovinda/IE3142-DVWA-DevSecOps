# Verify Command Injection Remediation
$loginUri = "http://127.0.0.1:4280/login.php"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Login
$loginPage = Invoke-WebRequest -Uri $loginUri -SessionVariable session -UseBasicParsing
if ($loginPage.Content -match "name='user_token' value='([a-f0-9]+)'") {
    $token = $matches[1]
    $loginData = @{ "username" = "admin"; "password" = "password"; "Login" = "Login"; "user_token" = $token }
    $null = Invoke-WebRequest -Uri $loginUri -Method POST -Body $loginData -WebSession $session -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
}

Write-Host "=========================================================="
Write-Host "1. Testing Legitimate Input (ip=127.0.0.1)"
Write-Host "=========================================================="
$cmdUri = "http://127.0.0.1:4280/vulnerabilities/exec/"
$bodyValid = @{ "ip" = "127.0.0.1"; "Submit" = "Submit" }
$resValid = Invoke-WebRequest -Uri $cmdUri -Method POST -Body $bodyValid -WebSession $session -UseBasicParsing
if ($resValid.Content -match "bytes from 127.0.0.1" -or $resValid.Content -match "packets transmitted") {
    Write-Host "[+] Legitimate ping succeeded!"
    $resValid.Content -split "`n" | Select-String -Pattern "packets transmitted|round-trip" | ForEach-Object { Write-Host "    $($_.Line.Trim())" }
} else {
    Write-Host "[-] Legitimate ping did not produce expected output."
}

Write-Host "`n=========================================================="
Write-Host "2. Retesting Identical Pre-Fix Attack Payload (127.0.0.1; whoami; id)"
Write-Host "=========================================================="
$bodyAttack = @{ "ip" = "127.0.0.1; whoami; id"; "Submit" = "Submit" }
$resAttack = Invoke-WebRequest -Uri $cmdUri -Method POST -Body $bodyAttack -WebSession $session -UseBasicParsing

$rceSuccess = $resAttack.Content -match "www-data" -or $resAttack.Content -match "uid=33"
$errorReturned = $resAttack.Content -match "ERROR: You have entered an invalid IP address format."

if (-not $rceSuccess -and $errorReturned) {
    Write-Host "[+] SUCCESS: Exploit blocked!"
    Write-Host "    Server Response: <pre>ERROR: You have entered an invalid IP address format.</pre>"
    Write-Host "    Arbitrary shell command execution was completely prevented."
} else {
    Write-Host "[-] Exploit was not blocked as expected."
}
Write-Host "=========================================================="
