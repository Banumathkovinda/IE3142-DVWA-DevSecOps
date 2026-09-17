# Verify CSRF Remediation
$loginUri = "http://127.0.0.1:4280/login.php"
$csrfUri = "http://127.0.0.1:4280/vulnerabilities/csrf/"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

# Login as admin
$loginPage = Invoke-WebRequest -Uri $loginUri -SessionVariable session -UseBasicParsing
if ($loginPage.Content -match "name='user_token' value='([a-f0-9]+)'") {
    $token = $matches[1]
    $loginData = @{ "username" = "admin"; "password" = "password"; "Login" = "Login"; "user_token" = $token }
    $null = Invoke-WebRequest -Uri $loginUri -Method POST -Body $loginData -WebSession $session -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
}

Write-Host "=========================================================="
Write-Host "1. Retesting Identical Pre-Fix Attack Payload (No Token)"
Write-Host "=========================================================="
$forgedUri = "http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=hacked123&password_conf=hacked123&Change=Change"
$resForged = Invoke-WebRequest -Uri $forgedUri -WebSession $session -UseBasicParsing
if ($resForged.Content -match "ERROR: CSRF token is missing or invalid" -and -not ($resForged.Content -match "Password Changed")) {
    Write-Host "[+] SUCCESS: Forged request blocked!"
    Write-Host "    Server Response: <pre>ERROR: CSRF token is missing or invalid. Action blocked.</pre>"
} else {
    Write-Host "[-] Forged request was not blocked."
}

Write-Host "`n=========================================================="
Write-Host "2. Testing Forged Request with Fake / Guess Token"
Write-Host "=========================================================="
$fakeTokenUri = "http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=hacked123&password_conf=hacked123&user_token=attacker_guessed_token&Change=Change"
$resFake = Invoke-WebRequest -Uri $fakeTokenUri -WebSession $session -UseBasicParsing
if ($resFake.Content -match "ERROR: CSRF token is missing or invalid") {
    Write-Host "[+] SUCCESS: Forged token blocked!"
    Write-Host "    Server Response: <pre>ERROR: CSRF token is missing or invalid. Action blocked.</pre>"
} else {
    Write-Host "[-] Fake token request was not blocked."
}

Write-Host "`n=========================================================="
Write-Host "3. Testing Legitimate Request with Valid Session Token"
Write-Host "=========================================================="
# Access the CSRF page legitimately to get current session's user_token
$formPage = Invoke-WebRequest -Uri $csrfUri -WebSession $session -UseBasicParsing
if ($formPage.Content -match "name='user_token' value='([a-f0-9]+)'") {
    $validToken = $matches[1]
    Write-Host "[*] Retrieved legitimate anti-CSRF token: $validToken"

    # Submit legitimate password change
    $legitUri = "http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=password&password_conf=password&user_token=$validToken&Change=Change"
    $resLegit = Invoke-WebRequest -Uri $legitUri -WebSession $session -UseBasicParsing

    if ($resLegit.Content -match "Password Changed") {
        Write-Host "[+] SUCCESS: Legitimate request with valid token succeeded!"
        Write-Host "    Server Response: <pre>Password Changed.</pre>"
    } else {
        Write-Host "[-] Legitimate request failed."
    }
} else {
    Write-Host "[-] Could not retrieve legitimate user_token from form."
}
Write-Host "=========================================================="
