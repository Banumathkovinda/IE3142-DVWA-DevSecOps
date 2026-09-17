# Helper script to initialize and seed DVWA database automatically
$uri = "http://127.0.0.1:4280/setup.php"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

Write-Host "[*] Fetching DVWA setup page..."
$response = Invoke-WebRequest -Uri $uri -SessionVariable session -UseBasicParsing

if ($response.Content -match "name='user_token' value='([a-f0-9]+)'") {
    $userToken = $matches[1]
    Write-Host "[+] Found CSRF user_token: $userToken"

    $postData = @{
        "create_db" = "Create / Reset Database"
        "user_token" = $userToken
    }

    Write-Host "[*] Submitting database initialization request..."
    $postResponse = Invoke-WebRequest -Uri $uri -Method POST -Body $postData -WebSession $session -UseBasicParsing

    if ($postResponse.Content -match "Database has been created" -or $postResponse.Content -match "users' table was created") {
        Write-Host "[+] SUCCESS: DVWA Database successfully initialized and seeded!"
    } else {
        Write-Host "[!] Note: Check setup response:"
        $postResponse.Content | Select-String -Pattern "message|created|error" | ForEach-Object { $_.Line }
    }
} else {
    Write-Host "[!] Failed to retrieve user_token from setup page."
}
