# Evidence 11 - SAST Scan (After Remediation)

## 1. Post-Remediation Scan Overview
Following the secure implementation of all four vulnerabilities, Semgrep SAST was re-executed with identical rule packs (`p/php` and `security/semgrep/rules/dvwa-rules.yml`) to evaluate remediation efficacy.

## 2. Scan Comparison Metrics
* **Baseline Codebase Findings**: 44
* **Post-Remediation Codebase Findings**: 38
* **Net Codebase Reduction**: **-6 blocking findings**
* **Findings on Target Modules (`low.php`)**: **0 (Reduced from 6 to ZERO)**
* **Custom Security Rule Findings**: **0 (Reduced from 2 to ZERO)**

### Detailed Comparison by Vulnerable Module
| Module / File | Baseline Finding(s) | Remediated Status | Remediated Code Mechanism |
| :--- | :--- | :---: | :--- |
| `app/vulnerabilities/sqli/source/low.php` | `php.lang.security.injection.tainted-sql-string` (Line 10, 31) | **0 Findings** (Eliminated) | PDO Prepared statements (`$db->prepare` + `bindParam`) and integer cast (`is_numeric`). |
| `app/vulnerabilities/exec/source/low.php` | `php.lang.security.tainted-exec.tainted-exec` (Line 10, 14) | **0 Findings** (Eliminated) | Strict 4-octet numeric whitelist + integer reconstruction + `escapeshellarg()`. |
| `app/vulnerabilities/xss_r/source/low.php` | `dvwa-reflected-xss-unescaped-echo` (Line 8) | **0 Findings** (Eliminated) | Context-aware `htmlspecialchars($name, ENT_QUOTES \| ENT_HTML5, 'UTF-8')`. |
| `app/vulnerabilities/csrf/source/low.php` | `dvwa-csrf-missing-token-check` (Line 3) | **0 Findings** (Eliminated) | Cryptographic `checkToken()` verification + form `tokenField()`. |

## 3. Explanation of Unremediated Codebase Findings
The remaining 38 findings in the codebase reside exclusively in unrelated intentional practice modules:
- File Inclusion (`fi/`)
- Blind SQL Injection (`sqli_blind/`)
- Insecure File Upload (`upload/`)
- Broken Access Control (`bac/`)
- Medium & High vulnerability tiers (`medium.php`, `high.php`)

These intentional lab files were preserved in accordance with project constraints to maintain the educational functionality of DVWA while proving targeted remediation on the four assigned vulnerabilities.

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `semgrep-after-terminal.png`: Terminal output showing the scan completed with 38 findings across the wider codebase and 0 findings in the four remediated `low.php` files.
- `semgrep-diff-comparison.png`: Side-by-side screenshot or table comparing baseline vs post-remediation metrics.
