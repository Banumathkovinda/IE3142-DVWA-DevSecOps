# Evidence 07 - Command Injection (After Remediation)

## 1. Remediation Strategy & Secure Code Design
The vulnerability was remediated by implementing strict input whitelisting and safe argument escaping:
1. **Strict IPv4 Octet Whitelist**: The input string is split using `explode('.', $target)`. The code validates:
   - Exactly 4 octets exist.
   - Each octet is strictly numeric (`is_numeric()`).
   - Each octet falls within the valid range `0 <= octet <= 255`.
2. **Safe Integer Reconstruction**: Rather than executing the raw user input, `$target` is reconstructed solely from sanitized integers:
   ```php
   $target = intval($octet[0]) . '.' . intval($octet[1]) . '.' . intval($octet[2]) . '.' . intval($octet[3]);
   ```
3. **Shell Escaping**: As defense-in-depth, `$target` is wrapped in `escapeshellarg()` before execution.
4. **Contextual Output Encoding**: Ping output is escaped with `htmlspecialchars()` before rendering.

## 2. Remediated Code (`app/vulnerabilities/exec/source/low.php`)
```php
<?php

if( isset( $_POST[ 'Submit' ]  ) ) {
    $target = trim( $_REQUEST[ 'ip' ] );
    $target = stripslashes( $target );

    // Security Control 1: Strict Allow-list Validation (IPv4 4-octet structure)
    $octet = explode( ".", $target );

    if( ( sizeof( $octet ) == 4 ) &&
        is_numeric( $octet[0] ) && is_numeric( $octet[1] ) &&
        is_numeric( $octet[2] ) && is_numeric( $octet[3] ) &&
        ( intval($octet[0]) >= 0 && intval($octet[0]) <= 255 ) &&
        ( intval($octet[1]) >= 0 && intval($octet[1]) <= 255 ) &&
        ( intval($octet[2]) >= 0 && intval($octet[2]) <= 255 ) &&
        ( intval($octet[3]) >= 0 && intval($octet[3]) <= 255 ) ) {

        // Security Control 2: Integer reconstruction
        $target = intval($octet[0]) . '.' . intval($octet[1]) . '.' . intval($octet[2]) . '.' . intval($octet[3]);

        // Security Control 3: Safe argument escaping
        $cmd = shell_exec( 'ping -c 4 ' . escapeshellarg( $target ) );
        $html .= "<pre>" . htmlspecialchars( $cmd, ENT_QUOTES, 'UTF-8' ) . "</pre>";
    } else {
        $html .= '<pre>ERROR: You have entered an invalid IP address format.</pre>';
    }
}
?>
```

## 3. Post-Fix Verification: Identical Attack Payload
The exact identical payload used during the pre-fix test (`127.0.0.1; whoami; id`) was submitted via POST.

### Verification Results
* **Endpoint URL**: `http://127.0.0.1:4280/vulnerabilities/exec/`
* **POST Body**: `ip=127.0.0.1%3B+whoami%3B+id&Submit=Submit`
* **Server Response**:
  ```html
  <pre>ERROR: You have entered an invalid IP address format.</pre>
  ```
* **Execution Status**: Zero operating system commands were executed. The semicolon `;` failed the numeric octet check and the request was immediately terminated.
* **Legitimate Functionality**: Submitting legitimate IP `127.0.0.1` runs the ping command safely:
  ```text
  4 packets transmitted, 4 received, 0% packet loss
  ```

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `cmd-after-blocked-browser.png`: Browser view showing payload `127.0.0.1; whoami; id` yielding "ERROR: You have entered an invalid IP address format."
- `cmd-after-ping-browser.png`: Browser view showing legitimate IP `127.0.0.1` returning standard ping statistics.
