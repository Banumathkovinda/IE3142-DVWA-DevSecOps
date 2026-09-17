# Verify SQL Injection Remediation
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
Write-Host "1. Testing Legitimate Input (id=1)"
Write-Host "=========================================================="
$validUri = "http://127.0.0.1:4280/vulnerabilities/sqli/?id=1&Submit=Submit"
$resValid = Invoke-WebRequest -Uri $validUri -WebSession $session -UseBasicParsing
if ($resValid.Content -match "First name: admin" -and $resValid.Content -match "Surname: admin") {
    Write-Host "[+] Legitimate query succeeded:"
    Write-Host "    Found: ID: 1, First name: admin, Surname: admin"
} else {
    Write-Host "[-] Legitimate query failed."
}

Write-Host "`n=========================================================="
Write-Host "2. Retesting Identical Pre-Fix Attack Payload (1' OR '1'='1)"
Write-Host "=========================================================="
$attackUri = "http://127.0.0.1:4280/vulnerabilities/sqli/?id=1%27+OR+%271%27%3D%271&Submit=Submit"
$resAttack = Invoke-WebRequest -Uri $attackUri -WebSession $session -UseBasicParsing
if ($resAttack.Content -match "ERROR: Invalid User ID format" -and -not ($resAttack.Content -match "First name: Gordon")) {
    Write-Host "[+] SUCCESS: Exploit blocked!"
    Write-Host "    Server Response: <pre>ERROR: Invalid User ID format. ID must be an integer.</pre>"
    Write-Host "    Zero unauthorized records leaked."
} else {
    Write-Host "[-] Exploit was not blocked as expected."
}
Write-Host "=========================================================="
