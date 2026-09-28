# DevSecOps Risk Register & 3x3 Assessment Matrix

## 1. Risk Evaluation Methodology

Risk is evaluated using a standard 3×3 quantitative risk model based on Likelihood and Impact:

$$\text{Risk Score} = \text{Likelihood} \times \text{Impact}$$

### Rating Scales
| Score | Likelihood Definition | Impact Definition |
| :---: | :--- | :--- |
| **1 (Low)** | Rare / complex exploit requiring high privileges or unlikely conditions. | Minimal damage; non-sensitive data; negligible operational effect. |
| **2 (Medium)** | Feasible under standard conditions; requires some user interaction or script tools. | Moderate disruption; partial unauthorized data access; account compromise. |
| **3 (High)** | Trivial to execute; publicly known payloads; directly exposed attack surface. | Critical failure; full database dump; remote code execution; loss of integrity. |

### Risk Matrix & Severity Classification
| Likelihood \ Impact | **1 (Low)** | **2 (Medium)** | **3 (High)** |
| :--- | :---: | :---: | :---: |
| **3 (High)** | 3 (Medium) | 6 (High) | **9 (High - Critical)** |
| **2 (Medium)** | 2 (Low) | 4 (Medium) | 6 (High) |
| **1 (Low)** | 1 (Low) | 2 (Low) | 3 (Medium) |

* **1 – 2**: **Low Risk** (Acceptable with standard hygiene)
* **3 – 4**: **Medium Risk** (Requires planned remediation and monitoring)
* **6 – 9**: **High Risk** (Unacceptable; must block pipeline / release)

---

## 2. Risk Register Summary Table

| Threat ID | STRIDE | Vulnerability / Threat | Pre-L | Pre-I | Pre-Score | Severity | Implemented Security Control | Post-L | Post-I | Post-Score | Residual Risk |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- | :---: | :---: | :---: | :---: |
| **TH-T01** | Tampering | SQL Injection (Data modification) | 3 | 3 | **9** | **High** | PDO Prepared Statements + `is_numeric()` | 1 | 2 | 2 | **Low** |
| **TH-I01** | Info Disc | SQL Injection (Data exfiltration) | 3 | 3 | **9** | **High** | Parameterized queries + suppress db error display | 1 | 2 | 2 | **Low** |
| **TH-E01** | Elev Priv | Command Injection (OS commands) | 3 | 3 | **9** | **High** | Whitelist IP octet validation (`is_numeric`) | 1 | 2 | 2 | **Low** |
| **TH-I02** | Info Disc | Reflected XSS (Session theft) | 3 | 2 | **6** | **High** | Context-aware `htmlspecialchars()` encoding | 1 | 1 | 1 | **Low** |
| **TH-T02** | Tampering | Cross-Site Request Forgery (Password reset) | 3 | 2 | **6** | **High** | Session-bound Anti-CSRF Token (`checkToken`) | 1 | 1 | 1 | **Low** |
| **TH-S01** | Spoofing | Session Hijacking / Cookie theft | 2 | 3 | **6** | **High** | XSS output encoding + SameSite/HttpOnly flags | 1 | 2 | 2 | **Low** |
| **TH-D01** | DoS | Fork Bomb via Command Injection | 2 | 3 | **6** | **High** | Shell metacharacter suppression via IP parsing | 1 | 1 | 1 | **Low** |
| **TH-R01** | Repudiation| Missing Audit Logs for Password changes | 2 | 2 | **4** | **Medium** | Transaction error logging in Apache/PHP logs | 1 | 1 | 1 | **Low** |

---

## 3. Detailed Threat & Risk Analysis Records

### Record 1: SQL Injection Data Exfiltration & Tampering
* **Threat ID**: `TH-T01` / `TH-I01`
* **STRIDE Category**: Tampering / Information Disclosure
* **Affected Component**: `app/vulnerabilities/sqli/source/low.php`
* **Target Asset**: MariaDB `users` table, MD5 password hashes, schema metadata
* **Attack Scenario**: Unsanitized input `$id` concatenated into SQL string `SELECT first_name, last_name FROM users WHERE user_id = '$id';`. Attacker supplies `1' OR '1'='1` or `1' UNION SELECT user, password FROM users #`.
* **Pre-Mitigation Likelihood**: **3 (High)** – Input field is exposed directly on web form without validation or authentication barrier.
* **Pre-Mitigation Impact**: **3 (High)** – Exposes entire database table; alters data logic.
* **Pre-Mitigation Risk Score**: **9 (High)**
* **Risk Justification**: Direct remote compromise of confidentiality and integrity of all user accounts.
* **Security Control**:
  - Replace dynamic SQL concatenation with PDO prepared statements and parameter binding.
  - Apply `is_numeric()` data type validation before query execution.
* **Control Location**: `app/vulnerabilities/sqli/source/low.php` and CI SAST Rule `security/semgrep/rules/php-sqli.yml`.
* **Post-Mitigation Likelihood**: **1 (Low)** – Database parser receives parameter out-of-band via binary protocol; injection payload cannot alter query structure.
* **Post-Mitigation Impact**: **2 (Medium)**
* **Residual Risk**: **2 (Low)** – Fully mitigated; residual risk confined to potential zero-day in underlying PDO driver.

---

### Record 2: OS Command Injection
* **Threat ID**: `TH-E01` / `TH-D01`
* **STRIDE Category**: Elevation of Privilege / Denial of Service
* **Affected Component**: `app/vulnerabilities/exec/source/low.php`
* **Target Asset**: Container operating system, `/bin/sh`, web server process environment
* **Attack Scenario**: User parameter `$target` passed directly to `shell_exec('ping -c 4 ' . $target)`. Attacker injects `; id; cat /etc/passwd` or `; :(){ :|:& };:`.
* **Pre-Mitigation Likelihood**: **3 (High)** – Direct text input evaluated by shell interpreter with no character filtering.
* **Pre-Mitigation Impact**: **3 (High)** – Arbitrary command execution under `www-data` account within container.
* **Pre-Mitigation Risk Score**: **9 (High)**
* **Risk Justification**: Permits attacker to execute arbitrary binaries, read server files, probe internal container networks, or trigger DoS.
* **Security Control**:
  - Strict input allow-list: parse input as four separate octets using `explode('.', $target)` and ensure each octet is an integer between 0 and 255.
  - Reconstruct sanitized IP before invoking execution.
* **Control Location**: `app/vulnerabilities/exec/source/low.php` and CI SAST Rule `security/semgrep/rules/php-command-injection.yml`.
* **Post-Mitigation Likelihood**: **1 (Low)** – Characters outside `0-9` and `.` are rejected with an error before reaching shell.
* **Post-Mitigation Impact**: **2 (Medium)**
* **Residual Risk**: **2 (Low)** – Completely prevents metacharacter interpretation.

---

### Record 3: Reflected Cross-Site Scripting (XSS)
* **Threat ID**: `TH-I02` / `TH-S01`
* **STRIDE Category**: Information Disclosure / Spoofing
* **Affected Component**: `app/vulnerabilities/xss_r/source/low.php`
* **Target Asset**: Victim browser session cookies (`PHPSESSID`), DOM state
* **Attack Scenario**: Parameter `$_GET['name']` reflected directly into `<pre>Hello ' . $_GET['name'] . '</pre>` with `X-XSS-Protection: 0`. Payload `<script>alert(document.cookie)</script>` executes in victim's browser context.
* **Pre-Mitigation Likelihood**: **3 (High)** – Readily exploitable via crafted URL link.
* **Pre-Mitigation Impact**: **2 (Medium)** – Session cookie exfiltration and account takeover.
* **Pre-Mitigation Risk Score**: **6 (High)**
* **Risk Justification**: Any user clicking the phishing link suffers complete session compromise.
* **Security Control**:
  - Context-aware HTML entity encoding using `htmlspecialchars($name, ENT_QUOTES | ENT_HTML5, 'UTF-8')`.
* **Control Location**: `app/vulnerabilities/xss_r/source/low.php` and CI SAST Rule `security/semgrep/rules/php-xss.yml`.
* **Post-Mitigation Likelihood**: **1 (Low)** – Browser treats payload characters `< > & "` as literal glyphs, not executable tags.
* **Post-Mitigation Impact**: **1 (Low)**
* **Residual Risk**: **1 (Low)** – Remediation complies with OWASP XSS Prevention Cheat Sheet.

---

### Record 4: Cross-Site Request Forgery (CSRF)
* **Threat ID**: `TH-T02`
* **STRIDE Category**: Tampering
* **Affected Component**: `app/vulnerabilities/csrf/source/low.php`
* **Target Asset**: User password in `users` table
* **Attack Scenario**: Password change action is accepted over HTTP GET without verifying origin or requiring a unique token. Attacker embeds `<img>` tag in an external forum that silently submits the password change URL.
* **Pre-Mitigation Likelihood**: **3 (High)** – Browsers automatically append session cookies to cross-origin requests.
* **Pre-Mitigation Impact**: **2 (Medium)** – Unauthorized credential change locked out the legitimate user.
* **Pre-Mitigation Risk Score**: **6 (High)**
* **Risk Justification**: Allows unauthenticated attackers to hijack accounts of any active user visiting an external page.
* **Security Control**:
  - Cryptographically secure anti-CSRF token generated per session (`generateSessionToken()`).
  - Strict server-side verification using `checkToken($_REQUEST['user_token'], $_SESSION['session_token'])`.
* **Control Location**: `app/vulnerabilities/csrf/source/low.php` and `app/dvwa/includes/dvwaPage.inc.php`.
* **Post-Mitigation Likelihood**: **1 (Low)** – Third-party origin cannot read or predict the pseudo-random session token.
* **Post-Mitigation Impact**: **1 (Low)**
* **Residual Risk**: **1 (Low)** – Forged requests are rejected immediately with "CSRF token is incorrect".
