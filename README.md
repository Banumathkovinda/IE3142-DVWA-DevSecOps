# IE3142: DevOps Security – Building and Securing a DevSecOps Pipeline Using DVWA

## 1. Academic Context & Project Overview
* **Module**: IE3142 DevOps Security
* **Project Title**: Building and Securing an Automated DevSecOps Pipeline Using Damn Vulnerable Web Application (DVWA)
* **Team**: 4-Member Engineering Group
* **Objective**: Implement a fully containerized, reproducible multi-tier web application architecture, integrate multi-scanner automated security gates (SAST, SCA, Secrets, Container Image Scanning) into a GitHub Actions CI/CD pipeline, and execute evidence-based exploit-and-remediation cycles for four critical OWASP vulnerabilities.

---

## 2. Architecture & Technology Stack

### Technology Inventory
* **Application**: Damn Vulnerable Web Application (DVWA) on PHP 8.2+ with Apache 2.4 (`mod_rewrite`)
* **Database**: MariaDB 10.11 LTS connected via internal bridge network (`dvwa-internal`)
* **Containerization**: Docker 29+ & Docker Compose v5+
* **SAST (Static Application Security Testing)**: Semgrep OSS (`p/php` + custom rules)
* **SCA (Software Composition Analysis)**: Composer Native Audit & Aquasec Trivy (`trivy fs`)
* **Secrets Scanning**: Gitleaks (`.gitleaks.toml`)
* **Container Scanning**: Aquasec Trivy (`trivy image`)
* **CI/CD Orchestrator**: GitHub Actions (`.github/workflows/devsecops.yml`)

### Architecture Summary
```text
Browser (Attacker / Student)
    │
    │ HTTP (127.0.0.1:4280)
    ▼
DVWA Web Container [Apache + PHP 8]
    │
    │ Internal Docker Network (dvwa-internal:3306)
    ▼
Database Container [MariaDB 10.11] ── Persistent Volume [dvwa-db-data]

CI/CD:
Git Push ──► GitHub Actions ──► Lint ──► SAST (Semgrep) ──► SCA (Trivy) ──► Secrets (Gitleaks) ──► Image Scan (Trivy) ──► Pass/Fail Gate
```

---

## 3. Prerequisites & Quickstart Setup

### Prerequisites
* Docker Desktop 24+ (running with Linux containers / WSL2 enabled)
* Git 2.40+
* Web browser (Chrome, Edge, Firefox)

### Step-by-Step Local Deployment
```bash
# 1. Clone the repository
git clone https://github.com/<your-org>/dvwa-devsecops.git
cd dvwa-devsecops

# 2. Configure environment variables
cp .env.example .env

# 3. Build and launch the container stack
docker compose up -d --build

# 4. Check container health status
docker compose ps
```

* **Web Application URL**: `http://127.0.0.1:4280`
* **Default Credentials**: `admin` / `password`

### Database Initialization
1. Navigate to `http://127.0.0.1:4280/setup.php` in your browser.
2. Click **Create / Reset Database** (or run `powershell -ExecutionPolicy Bypass -File scripts/init_dvwa.ps1`).
3. You will be redirected to the login page. Log in with `admin` // `password`.

---

## 4. Local Security Scan Execution Commands

All security tools can be executed locally without installing external software, using standard Docker containers:

### 4.1 SAST Scanning (Semgrep)
```bash
# Run Semgrep with standard PHP rules and custom DVWA rules:
docker run --rm -v "${PWD}:/src" returntocorp/semgrep semgrep scan \
  --config "p/php" \
  --config /src/security/semgrep/rules/dvwa-rules.yml \
  /src/app
```

### 4.2 Dependency / SCA Scanning (Trivy)
```bash
# Scan Composer lockfile dependencies for known CVEs:
docker run --rm -v "${PWD}:/src" aquasec/trivy:latest fs \
  --scanners vuln \
  /src/app/vulnerabilities/api
```

### 4.3 Secrets Scanning (Gitleaks)
```bash
# Scan Git history and working tree using policy configuration:
docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect \
  --source=/path \
  --config=/path/.gitleaks.toml \
  -v
```

### 4.4 Container Image Scanning (Trivy)
```bash
# Scan built DVWA image for critical vulnerabilities:
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
  --severity HIGH,CRITICAL \
  dvwa-devsecops-web:local
```

---

## 5. Vulnerabilities & Secure Remediation Summary

| Vulnerability | Pre-Fix Flaw | Remediation Mechanism | Remediated File |
| :--- | :--- | :--- | :--- |
| **SQL Injection** | Unsanitized `$_REQUEST['id']` concatenated into SQL query string | PDO Parameterized prepared statements (`$db->prepare`) + `is_numeric()` type check | `app/vulnerabilities/sqli/source/low.php` |
| **Reflected XSS** | Direct `$_GET['name']` echo into HTML response with `X-XSS-Protection: 0` | Context-aware HTML entity encoding using `htmlspecialchars($name, ENT_QUOTES \| ENT_HTML5, 'UTF-8')` | `app/vulnerabilities/xss_r/source/low.php` |
| **Command Injection** | Raw `shell_exec('ping ' . $target)` allowing command chaining (`;`, `&&`) | Strict IPv4 4-octet numeric allow-list, integer reconstruction, and `escapeshellarg()` | `app/vulnerabilities/exec/source/low.php` |
| **CSRF** | State-changing password reset via GET request without token validation | Synchronizer token validation with constant-time `hash_equals()` and form `tokenField()` | `app/vulnerabilities/csrf/source/low.php` |

---

## 6. CI/CD Security Pipeline & Gate Policy

The automated GitHub Actions workflow (`.github/workflows/devsecops.yml`) enforces five discrete stages:
1. **Lint & Config Validation**: Verifies `docker compose config` and environment schemas.
2. **SAST Security Gate**: Semgrep scans target PHP modules. Fails pipeline (`exit-code 1`) if any `ERROR` finding exists.
3. **Dependency / SCA Gate**: Trivy scans `composer.lock`. Fails on any `CRITICAL` library vulnerability.
4. **Secrets Gate**: Gitleaks inspects full commit history. Fails on any un-allowlisted secret.
5. **Container Security Gate**: Builds image and runs Trivy container scan. Fails on any fixable `CRITICAL` vulnerability.

---

## 7. Evidence Manifest & Directory Map

All evidence and screenshot placeholders are organized under `evidence/`:
* `01-original-dvwa/`: Container status (`docker compose ps`) and setup check logs.
* `02-sqli-before/` & `03-sqli-after/`: SQLi pre-fix exploit dump and post-fix blocking proof.
* `04-xss-before/` & `05-xss-after/`: Reflected XSS pre-fix DOM execution and post-fix encoded proof.
* `06-command-injection-before/` & `07-command-injection-after/`: Command injection RCE proof and post-fix allow-list rejection.
* `08-csrf-before/` & `09-csrf-after/`: CSRF forged GET reset and post-fix token rejection.
* `10-sast-before/` & `11-sast-after/`: Real Semgrep scan metrics (44 findings down to 38; 0 on fixed modules).
* `12-dependency-scan/`: Composer audit and Trivy fs dependency results.
* `13-gitleaks/`: Gitleaks commit scan results and `.gitleaks.toml` policy.
* `14-trivy/`: Trivy container image layer analysis.
* `15-pipeline-failed/`: Demonstration guide for controlled security gate failure.
* `16-pipeline-success/`: Demonstration guide for passing CI/CD pipeline.

---

## 8. Ethical Use Notice & Academic Disclaimer
This project is prepared strictly for educational purposes within the university curriculum of IE3142: DevOps Security. The application contains intentionally vulnerable components designed solely for secure development education. The container environment is bound strictly to `127.0.0.1` and must never be exposed to public networks.

---

## 9. Troubleshooting
* **Database connection error**: Ensure MariaDB container is healthy (`docker compose ps`). If connecting for the first time, run `setup.php` to initialize tables.
* **Port conflicts on 4280**: Change `APP_PORT=8080` in `.env` and restart (`docker compose up -d`).
* **Clean Reset**: To wipe and start from scratch, run `docker compose down -v` followed by `docker compose up -d --build`.
