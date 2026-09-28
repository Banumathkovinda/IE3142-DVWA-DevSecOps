# Semgrep SAST Implementation & Configuration

## 1. Tool Overview
Semgrep is a fast, open-source static analysis tool (SAST) for finding security vulnerabilities, bugs, and enforcing code standards. In this DevSecOps pipeline, Semgrep operates both locally (via Docker) and in GitHub Actions CI/CD to detect vulnerabilities before code is merged.

---

## 2. Configuration & Custom Rules
* **Standard Rule Pack**: `p/php` (Official Semgrep Registry rules for PHP security)
* **Custom Rules File**: `security/semgrep/rules/dvwa-rules.yml`
  * Rule 1: `dvwa-reflected-xss-unescaped-echo` (Detects unescaped HTML echoes)
  * Rule 2: `dvwa-csrf-missing-token-check` (Detects missing `checkToken()` on password modifications)

---

## 3. Local Execution Guide

### Option A: Via Docker (Recommended - Zero Installation)
Run the following command from the repository root:
```bash
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep scan \
  --config "p/php" \
  --config /src/security/semgrep/rules/dvwa-rules.yml \
  --json -o /src/security/semgrep/semgrep-results.json \
  /src/app
```

### Option B: Via Python pip
```bash
pip install semgrep
semgrep scan --config "p/php" --config security/semgrep/rules/dvwa-rules.yml app/
```

---

## 4. Policy Gate Configuration
In the CI/CD pipeline (`.github/workflows/devsecops.yml`), Semgrep is configured with:
```bash
semgrep scan --error --severity ERROR
```
If any finding with severity `ERROR` is detected in modified code, Semgrep exits with return code `1`, causing the CI security gate to fail.
