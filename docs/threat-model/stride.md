# STRIDE Threat Model

## 1. Scope & Objective
This threat model evaluates the containerized Damn Vulnerable Web Application (DVWA) DevSecOps implementation using Microsoft's STRIDE methodology. It identifies application-specific threats across data flows, components, and trust boundaries defined in the architecture specification.

---

## 2. STRIDE Threat Categorization & Analysis

### 2.1 Spoofing (S)
* **Threat ID**: `TH-S01`
* **Threat Title**: Session Hijacking via Stolen Session Identifiers & Insecure Cookies
* **STRIDE Category**: Spoofing
* **Affected Component**: DVWA Web Tier (`dvwa-web`, `dvwaPage.inc.php`, `login.php`)
* **Target Asset**: User session state, `PHPSESSID` cookie, administrative privileges
* **Attack Scenario**: An attacker tricks an authenticated user into clicking an XSS payload or intercepts unencrypted traffic on a local network. The script reads `document.cookie` containing `PHPSESSID` and sends it to an attacker server. The attacker reuses the cookie to impersonate the user without supplying credentials.
* **Security Control**:
  - Remediate XSS via contextual output encoding (`htmlspecialchars`).
  - Configure `HttpOnly` and `SameSite` flags on session cookies to prevent JavaScript access.
* **Control Location**: `app/dvwa/includes/dvwaPage.inc.php` and `app/vulnerabilities/xss_r/source/low.php`.

---

### 2.2 Tampering (T)

#### Threat 1: Database Tampering via SQL Injection
* **Threat ID**: `TH-T01`
* **STRIDE Category**: Tampering
* **Affected Component**: SQL Injection Module (`vulnerabilities/sqli/source/low.php`), MariaDB Engine (`dvwa-db`)
* **Target Asset**: Integrity of the `users` table, password hashes, application data
* **Attack Scenario**: An untrusted client submits malicious SQL fragments (e.g. `1' OR '1'='1`) into the `id` field. Because the PHP script constructs SQL queries via string interpolation without parameter binding, the attacker's input alters the query grammar, enabling unauthorized updates or table drops.
* **Security Control**: Enforce PDO parameterized queries with typed parameter binding (`PDO::PARAM_INT`) and validate that the input is numeric (`is_numeric()`).
* **Control Location**: `app/vulnerabilities/sqli/source/low.php`.

#### Threat 2: Unauthorized Password Change via Cross-Site Request Forgery (CSRF)
* **Threat ID**: `TH-T02`
* **STRIDE Category**: Tampering
* **Affected Component**: CSRF Module (`vulnerabilities/csrf/source/low.php`), MariaDB `users` table
* **Target Asset**: Authenticated user's account password
* **Attack Scenario**: While a victim is logged into DVWA, they browse a malicious third-party website or click an embedded link (`<img>` or `<iframe>`) containing `http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=evil&password_conf=evil&Change=Change`. Because the endpoint accepts GET requests without verifying request origin or an anti-CSRF token, the browser includes session cookies automatically, silently resetting the victim's password to `evil`.
* **Security Control**: Implement cryptographically secure session-bound anti-CSRF tokens (`generateSessionToken()`, `checkToken()`), require user verification of the existing password, and switch to POST requests.
* **Control Location**: `app/vulnerabilities/csrf/source/low.php` and `app/dvwa/includes/dvwaPage.inc.php`.

---

### 2.3 Repudiation (R)
* **Threat ID**: `TH-R01`
* **Threat Title**: Lack of Audit Logging for Sensitive Transactions
* **STRIDE Category**: Repudiation
* **Affected Component**: Web Tier logging, database transaction logging
* **Target Asset**: Accountability, forensics audit trail, non-repudiation
* **Attack Scenario**: An attacker compromises an account or modifies application settings. Because DVWA does not maintain an immutable audit log linking authenticated user identities, IP addresses, and state-changing actions, the attacker can deny performing the action, and defenders cannot reconstruct the incident sequence.
* **Security Control**: Implement security event logging for authentication attempts, failed CSRF validations, and password modifications to `syslog` or Apache error log (`error_log()`).
* **Control Location**: `app/login.php` and `app/dvwa/includes/dvwaPage.inc.php`.

---

### 2.4 Information Disclosure (I)

#### Threat 1: Database Exfiltration & Verbose Errors via SQL Injection
* **Threat ID**: `TH-I01`
* **STRIDE Category**: Information Disclosure
* **Affected Component**: SQL Injection Module (`vulnerabilities/sqli/source/low.php`), MariaDB Engine
* **Target Asset**: All user account records, MD5 password hashes, database schema metadata (`information_schema`)
* **Attack Scenario**: An attacker submits a `UNION SELECT` payload (e.g. `1' UNION SELECT user, password FROM users #`). The backend executes the union query and returns the first name and surname fields filled with usernames and password hashes directly into the HTML response. Additionally, syntax errors reveal internal database paths and schema names via `mysqli_error()`.
* **Security Control**: Use parameterized prepared statements, suppress verbose database error output in production mode (`display_errors = Off`), and restrict database user permissions.
* **Control Location**: `app/vulnerabilities/sqli/source/low.php` and `app/php.ini`.

#### Threat 2: DOM/Cookie Disclosure via Reflected Cross-Site Scripting (XSS)
* **Threat ID**: `TH-I02`
* **STRIDE Category**: Information Disclosure
* **Affected Component**: Reflected XSS Module (`vulnerabilities/xss_r/source/low.php`)
* **Target Asset**: Client DOM, session tokens, browser storage
* **Attack Scenario**: An attacker supplies a payload such as `<script>alert(document.cookie)</script>` in the `name` parameter. The server concatenates this directly into the HTML response without output encoding while explicitly setting `X-XSS-Protection: 0`. The victim's browser executes the script in the origin of DVWA, exposing sensitive data to the attacker.
* **Security Control**: Apply context-aware HTML output encoding using `htmlspecialchars($name, ENT_QUOTES | ENT_HTML5, 'UTF-8')`.
* **Control Location**: `app/vulnerabilities/xss_r/source/low.php`.

---

### 2.5 Denial of Service (D)
* **Threat ID**: `TH-D01`
* **Threat Title**: Process Starvation & Resource Exhaustion via Command Injection
* **STRIDE Category**: Denial of Service
* **Affected Component**: Command Execution Module (`vulnerabilities/exec/source/low.php`), Container OS
* **Target Asset**: CPU and memory availability of `dvwa-web` container
* **Attack Scenario**: An attacker injects a command such as `127.0.0.1; :(){ :|:& };:` (fork bomb) or an unbounded ping flood (`127.0.0.1; ping -c 1000000 localhost`) into the IP address field. The container allocates CPU cycles and processes until system resources are exhausted, making the web application unresponsive to other users.
* **Security Control**: Strictly validate input format using IPv4 octet parsing before command execution and set Docker container resource limits (`cpus`, `memory`).
* **Control Location**: `app/vulnerabilities/exec/source/low.php` and `docker-compose.yml`.

---

### 2.6 Elevation of Privilege (E)
* **Threat ID**: `TH-E01`
* **Threat Title**: Arbitrary OS Command Execution via Shell Injection
* **STRIDE Category**: Elevation of Privilege
* **Affected Component**: Command Execution Module (`vulnerabilities/exec/source/low.php`), Web Container Shell (`/bin/sh`)
* **Target Asset**: Container operating system, underlying file system, internal network access
* **Attack Scenario**: The application takes the `ip` parameter and executes `shell_exec('ping -c 4 ' . $target)`. An attacker inputs `127.0.0.1; id; cat /etc/passwd; whoami`. The shell interprets the semicolon `;` as a command separator and executes subsequent arbitrary commands under the `www-data` user account, granting the attacker a foothold inside the container.
* **Security Control**: Avoid shell interpretation by validating user input against a strict whitelist (verifying exactly four numeric octets in range 0-255).
* **Control Location**: `app/vulnerabilities/exec/source/low.php`.
