# Evidence 12 - Dependency & Software Composition Analysis (SCA)

## 1. Scan Execution Summary
* **Scan Target**: `app/vulnerabilities/api/composer.lock`
* **Direct Dependency**: `zircote/swagger-php: ^4.10`
* **SCA Scanners**:
  1. `composer audit --locked`
  2. Aquasec Trivy Filesystem Vulnerability Scanner (`trivy fs`)

## 2. Actual Terminal Outputs

### A. Composer Audit Output
```text
$ docker exec dvwa-web composer audit --locked --working-dir=/var/www/html/vulnerabilities/api
No security vulnerability advisories found.
```

### B. Aquasec Trivy Filesystem Scan Output
```text
$ docker run --rm -v "${PWD}:/src" aquasec/trivy:latest fs --scanners vuln /src/app/vulnerabilities/api
2026-09-17T22:27:01Z  INFO  [vuln] Vulnerability scanning is enabled
2026-09-17T22:27:01Z  INFO  Number of language-specific files  num=1
2026-09-17T22:27:01Z  INFO  [composer] Detecting vulnerabilities...

Report Summary

┌───────────────┬──────────┬─────────────────┐
│    Target     │   Type   │ Vulnerabilities │
├───────────────┼──────────┼─────────────────┤
│ composer.lock │ composer │        0        │
└───────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

## 3. Findings & Compliance Status
Both scanners independently confirmed that the external Composer dependencies utilized by DVWA have **zero known critical or high CVEs**.

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `trivy-fs-scan-terminal.png`: Terminal view of running `trivy fs --scanners vuln app/vulnerabilities/api` showing the clean `0` vulnerabilities table.
- `composer-audit-terminal.png`: Terminal view of `docker exec dvwa-web composer audit --locked ...` returning "No security vulnerability advisories found."
