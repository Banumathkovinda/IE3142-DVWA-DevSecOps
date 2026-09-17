# Dynamic Application Security Testing (DAST) - OWASP ZAP

## 1. Overview
Dynamic Application Security Testing (DAST) analyzes a running web application from the outside by sending HTTP requests and inspecting responses for vulnerabilities. OWASP ZAP (Zed Attack Proxy) is used for automated DAST scanning against the local containerized DVWA environment.

---

## 2. Local DAST Execution

### Prerequisites
Ensure the DVWA containers are running and healthy:
```bash
docker compose up -d
docker compose ps
```

### Running OWASP ZAP Baseline Scan (via Docker)
To perform an automated baseline scan against the local instance:
```bash
docker run --rm -v "${PWD}/security/zap:/zap/wrk/:rw" -t zaproxy/zap-stable \
  zap-baseline.py \
  -t "http://host.docker.internal:4280/" \
  -r zap-report.html \
  -J zap-report.json \
  -I
```

---

## 3. Scope & Ethical Testing Boundary
* **Target Origin**: Strictly confined to `http://127.0.0.1:4280` (Localhost loopback).
* **Isolation**: All tests execute within the local developer environment. No requests are directed toward external networks or production environments.
* **Scan Types**:
  * **Baseline Scan**: Rapid passive and light active scan for missing headers, cookie security flags, and information leaks.
  * **Authenticated Scan**: Optional spidering using session cookie (`PHPSESSID`) to probe protected endpoints.
