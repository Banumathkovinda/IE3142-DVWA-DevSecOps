# Trivy Container Image Security Scanning

## 1. Tool Overview
Aquasec Trivy is a comprehensive, vulnerability scanner designed for containers, operating system packages, and language-specific dependencies. In this pipeline, Trivy scans the container image built directly from `app/Dockerfile`.

---

## 2. Scanning Architecture & Scope
* **Target Image**: `dvwa-devsecops-web:local` (built from `php:8-apache` base)
* **Analyzed Layers**:
  1. **OS Packages (Debian base)**: Package managers (`dpkg`), system utilities (`util-linux`, `coreutils`, `openssl`).
  2. **Application Dependencies**: Composer packages installed under `/var/www/html/vulnerabilities/api/vendor/`.

---

## 3. Local Execution Commands

### Full Image Vulnerability Scan
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  dvwa-devsecops-web:local
```

### Actionable / Fixable Vulnerability Scan (`--ignore-unfixed`)
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --ignore-unfixed \
  --severity CRITICAL \
  dvwa-devsecops-web:local
```

---

## 4. Security Gate Policy & Thresholds
In `.github/workflows/devsecops.yml`, the container scan stage enforces an automated security gate:
* **Gate Policy**: Fails the pipeline (`exit-code 1`) if any **fixable CRITICAL vulnerability** (`--ignore-unfixed --severity CRITICAL`) is discovered in the built image.
* **Justified Acceptance Policy**: Unpatched upstream Debian base packages (`fix_deferred` or `affected` with no upstream patch available) are logged and monitored, avoiding unresolvable pipeline gridlock while strictly forbidding newly introduced fixable vulnerabilities.
