# Helper script to verify authentication against DVWA
$loginUri = "http://127.0.0.1:4280/login.php"
$indexUri = "http://127.0.0.1:4280/index.php"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

Write-Host "[*] Accessing DVWA login page..."
$loginPage = Invoke-WebRequest -Uri $loginUri -SessionVariable session -UseBasicParsing

if ($loginPage.Content -match "name='user_token' value='([a-f0-9]+)'") {
    $token = $matches[1]
    Write-Host "[+] Retrieved login CSRF token: $token"

    $loginData = @{
        "username" = "admin"
        "password" = "password"
        "Login" = "Login"
        "user_token" = $token
    }

    Write-Host "[*] Submitting login credentials (admin:password)..."
    $loginResult = Invoke-WebRequest -Uri $loginUri -Method POST -Body $loginData -WebSession $session -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue

    Write-Host "[*] Fetching main page (index.php)..."
    $indexResult = Invoke-WebRequest -Uri $indexUri -WebSession $session -UseBasicParsing

    if ($indexResult.Content -match "Welcome to Damn Vulnerable Web Application" -or $indexResult.Content -match "Logged in as 'admin'") {
        Write-Host "[+] SUCCESS: Successfully logged in as admin!"
        if ($indexResult.Content -match "Security Level: <em>([a-z]+)</em>") {
            Write-Host "[+] Current Security Level: $($matches[1])"
        }
    } else {
        Write-Host "[!] Login verification failed. Content snippet:"
        $indexResult.Content | Select-String -Pattern "Login|admin|Security Level" | ForEach-Object { $_.Line }
    }
} else {
    Write-Host "[!] Could not extract login user_token."
}
