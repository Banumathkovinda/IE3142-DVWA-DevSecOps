# Evidence 04 - Reflected Cross-Site Scripting (Before Remediation)

## 1. Vulnerability Overview
* **Vulnerable Module**: DVWA Reflected XSS (Cross-Site Scripting)
* **File Location**: `app/vulnerabilities/xss_r/source/low.php`
* **Vulnerability Class**: CWE-79 (Improper Neutralization of Input During Web Page Generation) / OWASP A03:2021 - Injection
* **Default Security Level**: `low`

## 2. Vulnerable Code Analysis
In `app/vulnerabilities/xss_r/source/low.php`:
```php
<?php

header ("X-XSS-Protection: 0");

// Is there any input?
if( array_key_exists( "name", $_GET ) && $_GET[ 'name' ] != NULL ) {
    // Feedback for end user
    $html .= '<pre>Hello ' . $_GET[ 'name' ] . '</pre>';
}

?>
```
1. Explicitly disables browser XSS auditor via `header("X-XSS-Protection: 0")`.
2. Reads parameter `$_GET['name']` and concatenates it directly into the HTML response `$html` without contextual encoding (`htmlspecialchars` or `htmlentities`).

## 3. Pre-Fix Attack Procedure & Live Payload
* **Endpoint URL**: `http://127.0.0.1:4280/vulnerabilities/xss_r/`
* **HTTP Method**: `GET`
* **Test Payload**:
  ```html
  <script>alert('XSS-VULNERABLE')</script>
  ```
* **Full Exploitation URL**:
  ```text
  http://127.0.0.1:4280/vulnerabilities/xss_r/?name=%3Cscript%3Ealert('XSS-VULNERABLE')%3C%2Fscript%3E
  ```

## 4. Expected & Actual Vulnerable Behavior
The server echoes raw HTML and JavaScript tags directly back in the HTTP response body:
```html
<pre>Hello <script>alert('XSS-VULNERABLE')</script></pre>
```
The browser parses and executes the `<script>` tag within the origin of `http://127.0.0.1:4280`.

### Live Terminal Proof (Automated Test Execution)
```text
[*] Request URI: http://127.0.0.1:4280/vulnerabilities/xss_r/?name=%3Cscript%3Ealert('XSS-VULNERABLE')%3C%2Fscript%3E
[!] EXPLOIT SUCCESS (VULNERABLE): Unescaped script tag reflected directly into DOM!
    Extracted HTML: <pre>Hello <script>alert('XSS-VULNERABLE')</script></pre>
```

## 5. Security Impact
- **Session Hijacking**: An attacker can exfiltrate `document.cookie` (`PHPSESSID`) to steal authenticated sessions.
- **Client-Side Phishing & Defacement**: Arbitrary DOM manipulation.
- **Pre-Mitigation Risk Rating**: **Likelihood: 3 (High)** × **Impact: 2 (Medium)** = **6 (High)**.

## 6. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `xss-before-popup.png`: Browser view showing JavaScript alert dialog box popping up with text `'XSS-VULNERABLE'`.
- `xss-before-dom-source.png`: Browser developer tools "Inspect Elements" view showing raw unescaped `<script>` tags inside `<pre>`.
