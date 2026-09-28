# Evidence 10 - SAST Scan (Before Remediation)

## 1. SAST Tool & Scan Configuration
* **SAST Tool**: Semgrep OSS (Docker image `returntocorp/semgrep:latest`)
* **Rule Packs Used**:
  - Built-in Semgrep ruleset: `p/php`
  - Custom DVWA ruleset: `security/semgrep/rules/dvwa-rules.yml`
* **Scan Target**: Entire codebase (`/var/www/html` or local repository `app/`)
* **Output Format**: Machine-readable JSON (`security/semgrep/semgrep-baseline.json`) and terminal table.

## 2. Local Execution Commands
```bash
# Full codebase scan with official Semgrep PHP pack:
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep scan --config "p/php" --json -o /src/security/semgrep/semgrep-baseline.json

# Scan target modules with custom security rules:
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep scan --config /src/security/semgrep/rules/dvwa-rules.yml /src/app/vulnerabilities/
```

## 3. Real Baseline Scan Summary
* **Total Rules Evaluated**: 23 standard PHP rules + 2 custom security rules
* **Total Files Scanned**: 170 PHP source files
* **Codebase Findings Total**: **44 findings** across all modules
* **Findings on Target Vulnerable Modules (`low.php`)**: **6 findings** (plus custom rule detections)

### Detailed Findings Breakdown on Target Vulnerabilities
| File | Line | Rule ID | Severity | Description |
| :--- | :---: | :--- | :---: | :--- |
| `app/vulnerabilities/sqli/source/low.php` | 10 | `php.lang.security.injection.tainted-sql-string` | **ERROR** | User data flows into manually-constructed SQL string without prepared statements. |
| `app/vulnerabilities/sqli/source/low.php` | 31 | `php.lang.security.injection.tainted-sql-string` | **ERROR** | User data flows into manually-constructed SQLite query string. |
| `app/vulnerabilities/exec/source/low.php` | 10 | `php.lang.security.tainted-exec.tainted-exec` | **ERROR** | Executing non-constant shell commands; prone to command injection. |
| `app/vulnerabilities/exec/source/low.php` | 14 | `php.lang.security.tainted-exec.tainted-exec` | **ERROR** | Executing non-constant shell commands; prone to command injection. |
| `app/vulnerabilities/xss_r/source/low.php` | 8 | `dvwa-reflected-xss-unescaped-echo` | **ERROR** | Untrusted `$_GET` input concatenated into HTML response without output encoding. |
| `app/vulnerabilities/csrf/source/low.php` | 3 | `dvwa-csrf-missing-token-check` | **WARNING** | State-changing password change request does not validate anti-CSRF token. |

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `semgrep-baseline-terminal.png`: Terminal screenshot of running Semgrep scan showing the 44 findings and specific alerts on `sqli/source/low.php` and `exec/source/low.php`.
- `semgrep-baseline-json.png`: Screenshot of `security/semgrep/semgrep-baseline.json` opened in VS Code / IDE.
