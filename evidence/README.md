# Evidence Manifest & Academic Checklist

This checklist tracks all required submission artifacts, logs, and screenshots across the 18 phases of the IE3142 DevSecOps project.

---

## Master Evidence Checklist

| Item # | Verification Category | Directory / Artifact Location | Description / Evidence Captured | Status |
| :---: | :--- | :--- | :--- | :---: |
| **01** | Original DVWA Running | `evidence/01-original-dvwa/` | `docker compose ps` healthy status, setup page verification, admin login | **Complete** |
| **02** | Multi-Container Architecture | `docs/architecture/` | Architecture document, component table, Mermaid data flow diagrams | **Complete** |
| **03** | Threat Model & Risk Matrix | `docs/threat-model/`, `docs/risk-assessment/` | STRIDE analysis (8 threats), 3x3 risk register before and after remediation | **Complete** |
| **04** | SQL Injection (Before) | `evidence/02-sqli-before/` | Live payload `1' OR '1'='1` dumping `admin`, `Gordon`, `Hack` records | **Complete** |
| **05** | SQL Injection (After) | `evidence/03-sqli-after/` | Parameterized prepared statement blocking identical payload | **Complete** |
| **06** | Reflected XSS (Before) | `evidence/04-xss-before/` | Unencoded `<script>alert('XSS-VULNERABLE')</script>` in DOM | **Complete** |
| **07** | Reflected XSS (After) | `evidence/05-xss-after/` | Context-aware `htmlspecialchars()` output encoding proof | **Complete** |
| **08** | Command Injection (Before) | `evidence/06-command-injection-before/` | Chained execution `127.0.0.1; whoami; id` returning `uid=33(www-data)` | **Complete** |
| **09** | Command Injection (After) | `evidence/07-command-injection-after/` | Strict IPv4 4-octet numeric whitelist rejecting metacharacters | **Complete** |
| **10** | CSRF (Before) | `evidence/08-csrf-before/` | Unauthorized GET password reset without anti-CSRF token | **Complete** |
| **11** | CSRF (After) | `evidence/09-csrf-after/` | Cryptographic `checkToken()` verification & constant-time comparison | **Complete** |
| **12** | SAST Scan (Before) | `evidence/10-sast-before/` | Real Semgrep scan baseline (44 codebase findings, 6 on target files) | **Complete** |
| **13** | SAST Scan (After) | `evidence/11-sast-after/` | Real Semgrep scan post-fix (38 codebase findings, **0 on target files**) | **Complete** |
| **14** | Dependency / SCA Scan | `evidence/12-dependency-scan/` | `composer audit` and Trivy fs scan confirming 0 CVEs in `composer.lock` | **Complete** |
| **15** | Secrets Detection | `evidence/13-gitleaks/` | Gitleaks commit scan and `.gitleaks.toml` policy pass (0 leaks found) | **Complete** |
| **16** | Container Image Scan | `evidence/14-trivy/` | Trivy container image scan of `dvwa-devsecops-web:local` | **Complete** |
| **17** | Security Gate Failure Demo | `evidence/15-pipeline-failed/` | Deliberate flaw demonstration showing pipeline failing on exit code 1 | **Complete** |
| **18** | Security Gate Success Demo | `evidence/16-pipeline-success/` | Clean pipeline execution overview across all 5 automated stages | **Complete** |
| **19** | Secrets Management | `docs/secrets-management.md` | Policy on `.env.example`, runtime env injection, and rotation protocol | **Complete** |

---

## Screenshot Mapping Guide for Academic Submission

Place the following captured PNG files into their designated subdirectories:
```text
evidence/
├── 01-original-dvwa/
│   ├── 01-docker-compose-ps.png
│   ├── 02-dvwa-setup-page.png
│   └── 03-dvwa-logged-in-index.png
├── 02-sqli-before/
│   ├── sqli-before-browser.png
│   └── sqli-before-burp-or-terminal.png
├── 03-sqli-after/
│   ├── sqli-after-blocked-browser.png
│   └── sqli-after-legitimate-browser.png
├── 04-xss-before/
│   ├── xss-before-popup.png
│   └── xss-before-dom-source.png
├── 05-xss-after/
│   ├── xss-after-browser.png
│   └── xss-after-source.png
├── 06-command-injection-before/
│   ├── cmd-injection-before-browser.png
│   └── cmd-injection-before-post.png
├── 07-command-injection-after/
│   ├── cmd-after-blocked-browser.png
│   └── cmd-after-ping-browser.png
├── 08-csrf-before/
│   ├── csrf-before-browser.png
│   └── csrf-before-poc-html.png
├── 09-csrf-after/
│   ├── csrf-after-blocked-browser.png
│   └── csrf-after-legitimate-browser.png
├── 10-sast-before/
│   ├── semgrep-baseline-terminal.png
│   └── semgrep-baseline-json.png
├── 11-sast-after/
│   ├── semgrep-after-terminal.png
│   └── semgrep-diff-comparison.png
├── 12-dependency-scan/
│   ├── trivy-fs-scan-terminal.png
│   └── composer-audit-terminal.png
├── 13-gitleaks/
│   ├── gitleaks-scan-clean-terminal.png
│   └── gitleaks-config-toml.png
├── 14-trivy/
│   ├── trivy-image-scan-terminal.png
│   └── trivy-clean-packages.png
├── 15-pipeline-failed/
│   ├── gh-actions-failed-summary.png
│   └── gh-actions-failed-logs.png
└── 16-pipeline-success/
    ├── gh-actions-success-summary.png
    └── gh-actions-job-details.png
```
