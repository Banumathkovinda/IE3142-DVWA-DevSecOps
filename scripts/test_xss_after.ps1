# Verify Reflected XSS Remediation
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
Write-Host "1. Testing Legitimate Input (name=Alice)"
Write-Host "=========================================================="
$validUri = "http://127.0.0.1:4280/vulnerabilities/xss_r/?name=Alice"
$resValid = Invoke-WebRequest -Uri $validUri -WebSession $session -UseBasicParsing
if ($resValid.Content -match "<pre>Hello Alice</pre>") {
    Write-Host "[+] Legitimate input rendered successfully: <pre>Hello Alice</pre>"
} else {
    Write-Host "[-] Legitimate input failed."
}

Write-Host "`n=========================================================="
Write-Host "2. Retesting Identical Pre-Fix Attack Payload (<script>alert('XSS-VULNERABLE')</script>)"
Write-Host "=========================================================="
$xssPayload = "<script>alert('XSS-VULNERABLE')</script>"
$attackUri = "http://127.0.0.1:4280/vulnerabilities/xss_r/?name=" + [System.Uri]::EscapeDataString($xssPayload)
$resAttack = Invoke-WebRequest -Uri $attackUri -WebSession $session -UseBasicParsing

Write-Host "[*] Request URI: $attackUri"
$expectedEncoded = "&lt;script&gt;alert(&#039;XSS-VULNERABLE&#039;)&lt;/script&gt;"
$rawScriptPresent = $resAttack.Content.Contains("<script>alert('XSS-VULNERABLE')</script>")
$encodedScriptPresent = $resAttack.Content.Contains($expectedEncoded) -or $resAttack.Content.Contains("&lt;script&gt;alert(&apos;XSS-VULNERABLE&apos;)&lt;/script&gt;")

if (-not $rawScriptPresent -and $encodedScriptPresent) {
    Write-Host "[+] SUCCESS: Exploit blocked!"
    Write-Host "    Raw <script> tags were NOT found in the HTTP response."
    Write-Host "    Safely encoded entities found: $expectedEncoded"
    Write-Host "    The browser renders the payload as harmless text, preventing JavaScript execution."
} else {
    Write-Host "[-] XSS payload was not encoded properly."
    $resAttack.Content -split "`n" | Select-String -Pattern "Hello" | ForEach-Object { Write-Host $_.Line.Trim() }
}
Write-Host "=========================================================="
