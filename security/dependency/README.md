# Software Composition Analysis (SCA) & Dependency Scanning

## 1. Dependency Model Overview
DVWA utilizes the PHP Composer dependency manager for its API vulnerability module located at `app/vulnerabilities/api/`:
* **Manifest File**: `app/vulnerabilities/api/composer.json`
  * Direct Dependency: `"zircote/swagger-php": "^4.10"`
* **Lock File**: `app/vulnerabilities/api/composer.lock`
  * Transitive Dependencies: `symfony/yaml`, `symfony/finder`, `symfony/deprecation-contracts`, `psr/log`, `symfony/polyfill-ctype`.

---

## 2. Scanning Tools & Methodology
To guarantee comprehensive coverage, two independent SCA tools are integrated into the DevSecOps lifecycle:
1. **Composer Native Audit (`composer audit`)**: Native PHP security advisory database scanner that checks installed and locked packages against the FriendsOfPHP security advisories database.
2. **Aquasec Trivy Filesystem SCA (`trivy fs`)**: Comprehensive open-source vulnerability scanner that parses `composer.lock` against the National Vulnerability Database (NVD) and GitHub Advisory Database.

---

## 3. Local Execution Commands

### Command A: Composer Native Audit
Run inside the running DVWA web container:
```bash
docker exec dvwa-web composer audit --locked --working-dir=/var/www/html/vulnerabilities/api
```

### Command B: Trivy Filesystem Scan (via Docker)
```bash
docker run --rm -v "${PWD}:/src" aquasec/trivy:latest fs \
  --scanners vuln \
  --severity HIGH,CRITICAL \
  /src/app/vulnerabilities/api
```

---

## 4. Pipeline Policy & Severity Gate
In the GitHub Actions pipeline (`.github/workflows/devsecops.yml`), the dependency scanning step enforces:
```bash
trivy fs --exit-code 1 --severity CRITICAL --scanners vuln app/vulnerabilities/api
```
* **Policy Threshold**: Any vulnerability with CVSS severity **CRITICAL** discovered in third-party libraries causes the pipeline job to terminate with non-zero exit code (`1`), preventing code deployment.
* **Current Scan Result**: Clean (`0` vulnerabilities detected in `composer.lock`).
