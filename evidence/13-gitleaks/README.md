# Evidence 13 - Secrets Scanning (Gitleaks)

## 1. Scan Execution Summary
* **Tool**: Gitleaks OSS (Docker image `zricethezav/gitleaks:latest`)
* **Policy Config**: `.gitleaks.toml`
* **Scan Scope**: Entire Git commit history and current working directory

## 2. Terminal Outputs & Findings

### Initial Raw Scan Finding (Educational Dummy Token)
When executed without custom policy, Gitleaks detected a static dummy CSRF token in DVWA help text:
```text
Finding:     user-token: 026d0caed93471b507ed460ebddbd096
Secret:      026d0caed93471b507ed460ebddbd096
RuleID:      generic-api-key
File:        app/vulnerabilities/csrf/help/help.php:54
10:28PM WRN leaks found: 1
```

### Policy-Enforced Scan Execution (`.gitleaks.toml`)
With `.gitleaks.toml` explicitly allowlisting the static documentation token, the scan executed cleanly:
```text
$ docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source=/path --config=/path/.gitleaks.toml -v

    ○
    │╲
    │ ○
    ○ ░
    ░    gitleaks

10:28PM INF 6 commits scanned.
10:28PM INF scanned ~1261129 bytes (1.26 MB) in 3.96s
10:28PM INF no leaks found
```

## 3. Compliance & Security Gate Status
* **Exit Code**: `0`
* **Status**: **PASS**
* **Active Secrets Detected**: `0`
* **Security Gate Policy**: Zero plain-text credentials or API tokens permitted in repository commits.

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `gitleaks-scan-clean-terminal.png`: Terminal view showing `gitleaks detect ...` with output `no leaks found` and exit code 0.
- `gitleaks-config-toml.png`: Screenshot of `.gitleaks.toml` opened in IDE demonstrating the documented allowlist policy.
