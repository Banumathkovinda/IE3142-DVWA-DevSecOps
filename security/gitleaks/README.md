# Gitleaks Secrets Scanning Implementation

## 1. Tool Overview
Gitleaks is a dedicated, high-performance static secrets detector for Git repositories, designed to detect hardcoded secrets like passwords, API keys, private tokens, and credentials in code and commit history.

---

## 2. Configuration & Allowlist Policy (`.gitleaks.toml`)
DVWA includes educational help pages with example HTTP requests containing dummy hex tokens (such as `user-token: 026d0caed93471b507ed460ebddbd096` in `app/vulnerabilities/csrf/help/help.php`).

Rather than disabling Gitleaks or using broad exclusions, `.gitleaks.toml` defines a justified, scoped allowlist:
```toml
title = "DVWA DevSecOps Gitleaks Policy"

[extend]
useDefault = true

[allowlist]
description = "Allowlist static dummy CSRF tokens in DVWA help documentation"
paths = [
    '''app/vulnerabilities/csrf/help/help\.php''',
    '''evidence/.*''',
    '''docs/.*'''
]
stopwords = [
    "026d0caed93471b507ed460ebddbd096"
]
```

---

## 3. Local Execution Guide

### Run Gitleaks via Docker
```bash
docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect \
  --source=/path \
  --config=/path/.gitleaks.toml \
  -v
```

---

## 4. Pipeline Security Gate
In `.github/workflows/devsecops.yml`, Gitleaks runs as an automated security stage:
* If any un-allowlisted secret, token, or private key is detected, Gitleaks returns exit code `1`.
* The workflow fails immediately, preventing exposed secrets from entering production or being published.
