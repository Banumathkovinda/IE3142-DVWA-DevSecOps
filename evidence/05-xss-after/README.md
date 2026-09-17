# Evidence 05 - Reflected Cross-Site Scripting (After Remediation)

## 1. Remediation Strategy & Secure Code Design
The vulnerability was remediated by implementing context-aware output encoding in strict alignment with the OWASP XSS Prevention Cheat Sheet:
1. **HTML Entity Encoding**: User-controlled data `$_GET['name']` is passed through `htmlspecialchars($name, ENT_QUOTES | ENT_HTML5, 'UTF-8')`.
   - Converts `<` to `&lt;`
   - Converts `>` to `&gt;`
   - Converts `"` to `&quot;`
   - Converts `'` to `&#039;`
   - Converts `&` to `&amp;`
2. **Security Headers**: Removed `X-XSS-Protection: 0` header and added `X-Content-Type-Options: nosniff`.
3. **Execution Context**: The browser HTML parser interprets encoded entities strictly as text characters, preventing the browser from switching into JavaScript execution mode.

## 2. Remediated Code (`app/vulnerabilities/xss_r/source/low.php`)
```php
<?php

// Security Control 1: Hardened browser response header
header( "X-Content-Type-Options: nosniff" );

// Is there any input?
if( array_key_exists( "name", $_GET ) && $_GET[ 'name' ] != NULL ) {
    // Security Control 2: Context-aware HTML entity output encoding
    $name = htmlspecialchars( $_GET[ 'name' ], ENT_QUOTES | ENT_HTML5, 'UTF-8' );

    // Safely rendered as literal text
    $html .= "<pre>Hello {$name}</pre>";
}

?>
```

## 3. Post-Fix Verification: Identical Attack Payload
The exact identical payload used during the pre-fix test (`<script>alert('XSS-VULNERABLE')</script>`) was submitted to the remediated endpoint.

### Verification Results
* **Endpoint URL**: `http://127.0.0.1:4280/vulnerabilities/xss_r/?name=%3Cscript%3Ealert('XSS-VULNERABLE')%3C%2Fscript%3E`
* **Raw HTML in Response**:
  ```html
  <pre>Hello &lt;script&gt;alert(&#039;XSS-VULNERABLE&#039;)&lt;/script&gt;</pre>
  ```
* **Execution Status**: Zero JavaScript executed; alert dialog does not trigger.
* **Legitimate Functionality**: Submitting legitimate name `Alice` renders:
  ```html
  <pre>Hello Alice</pre>
  ```

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `xss-after-browser.png`: Browser view showing the payload displayed as literal, visible text (`<script>alert('XSS-VULNERABLE')</script>`) on the page without any alert dialog.
- `xss-after-source.png`: Browser "View Source" / DevTools showing the entities rendered as `&lt;script&gt;...&lt;/script&gt;`.
