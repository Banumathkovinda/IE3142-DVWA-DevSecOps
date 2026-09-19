# Four-Member Git Contribution & Task Allocation Plan

## 1. Objective & Collaboration Model
To ensure each of the four group members makes distinct, verifiable, and meaningful contributions to the project repository, work is partitioned across logical branches, secure coding remediations, threat modeling, and CI/CD security automation.

---

## 2. Member Responsibilities & Role Matrix

| Group Member | Primary Focus Area | Assigned Branches | Key Deliverables & Commits |
| :--- | :--- | :--- | :--- |
| **Member 1: Banumathkovinda**<br/>`banumathkovinda954@gmail.com`<br/>*(DevOps & Environment Lead)* | Docker Topology, Health Checks, Secrets Management, Trivy Container Scanning | `devsecops/pipeline`<br/>`feature/docker-baseline` | - `docker-compose.yml`, `app/Dockerfile`<br/>- `.env.example`, `.gitignore`<br/>- `docs/architecture/architecture.md`<br/>- `security/trivy/`, `evidence/14-trivy/` |
| **Member 2: AshenAloka**<br/>`alokaashen777@gmail.com`<br/>*(Security Lead: SQLi & Threat Modeling)* | STRIDE Threat Model, 3x3 Risk Register, SQL Injection Exploit & Remediation | `docs/threat-model`<br/>`feature/sql-injection-fix` | - `docs/threat-model/stride.md`<br/>- `docs/risk-assessment/risk-register.md`<br/>- `app/vulnerabilities/sqli/source/low.php`<br/>- `evidence/02-sqli-before/`, `evidence/03-sqli-after/` |
| **Member 3: Teshan242**<br/>`pasindukumarasinghe200@gmail.com`<br/>*(Security Lead: XSS & SAST Semgrep)* | Reflected XSS Remediation, Semgrep Rule Writing, Baseline & Post-Fix Scans | `feature/xss-fix`<br/>`security/semgrep` | - `app/vulnerabilities/xss_r/source/low.php`<br/>- `security/semgrep/rules/dvwa-rules.yml`<br/>- `evidence/04-xss-before/`, `evidence/05-xss-after/`<br/>- `evidence/10-sast-before/`, `evidence/11-sast-after/` |
| **Member 4: Denith-Ariyapperuma**<br/>`ariyapperumadenith@gmail.com`<br/>*(Security Lead: CMD Injection & CSRF)* | Command Injection Fix, CSRF Synchronizer Token Fix, Gitleaks & CI Failure Demo | `feature/command-injection-fix`<br/>`feature/csrf-fix`<br/>`demo/failed-pipeline` | - `app/vulnerabilities/exec/source/low.php`<br/>- `app/vulnerabilities/csrf/source/low.php`<br/>- `.gitleaks.toml`, `evidence/13-gitleaks/`<br/>- `evidence/15-pipeline-failed/`, `evidence/16-pipeline-success/` |

---

## 3. Recommended Logical Commit History Sequence

```text
* eae842b (HEAD -> main) docs: add SAST and exploit before-and-after evidence guides and test scripts
* e8156b0 (feature/csrf-fix) fix: add CSRF token validation with constant-time comparison and tokenField in form
* a473dc1 (feature/command-injection-fix) fix: harden command input handling using IPv4 whitelist and escapeshellarg
* d324d85 (feature/xss-fix) fix: encode XSS output using htmlspecialchars and add nosniff header
* c42fe79 (feature/sql-injection-fix) fix: remediate SQL injection with prepared statement and input validation
* 076ec69 chore: establish reproducible DVWA Docker baseline and architecture documentation
```

---

## 4. Branching & Pull Request Workflow

1. **Clone & Branch Creation**:
   ```bash
   git checkout -b feature/<feature-name>
   ```
2. **Commit Code Changes**:
   ```bash
   git add <modified-files>
   git commit -m "<type>: <concise description of security change>"
   ```
3. **Run Pre-Commit Checks**:
   - Verify Semgrep SAST: `scripts/parse_semgrep.ps1`
   - Verify Gitleaks: `docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source=/path --config=/path/.gitleaks.toml`
   - Run verification tests: `scripts/test_<vulnerability>_after.ps1`
4. **Push & Pull Request**:
   - Push branch to GitHub: `git push origin feature/<feature-name>`
   - Open Pull Request to `main`
   - Wait for all 5 GitHub Actions security gates to turn GREEN before merging.
