# Secrets Management Policy & Lifecycle

## 1. Overview & Principles
In accordance with DevSecOps best practices and the Principle of Least Privilege:
1. **Zero Plaintext Secrets**: Passwords, API keys, and connection credentials must never be committed to Git.
2. **Environment Variable Injection**: The application and database containers consume configurations strictly at runtime via environment variables.
3. **Automated Enforcement**: Gitleaks enforces secrets detection on all commits and pull requests before merging.

---

## 2. Secrets Inventory (Identifiers Only)

| Secret Name | Local Source | CI/CD Source | Consumer Component | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `DB_PASSWORD` | Local `.env` | GitHub Actions Secret / Default | `dvwa-web` & `dvwa-db` | MariaDB password for application user `dvwa` |
| `MYSQL_ROOT_PASSWORD` | Local `.env` | GitHub Actions Secret / Default | `dvwa-db` | MariaDB database administrative root password |
| `RECAPTCHA_PRIVATE_KEY`| Local `.env` | GitHub Actions Secret | `dvwa-web` | Google ReCAPTCHA API private validation key |
| `GITHUB_TOKEN` | N/A | Automated CI Secret | Gitleaks Action | Read permissions for pull requests and status checks |

---

## 3. Provisioning Workflows

### 3.1 Local Workstation Provisioning
1. The developer clones the repository.
2. The template configuration `.env.example` is copied to `.env`:
   ```bash
   cp .env.example .env
   ```
3. The developer sets unique, high-entropy passwords in `.env`.
4. `.gitignore` strictly prevents `.env` from being added to Git:
   ```text
   .env
   .env.local
   .env.*.local
   ```
5. `docker-compose.yml` automatically passes variables into container environments.

### 3.2 GitHub Actions CI/CD Provisioning
1. Sensitive values are registered under **Repository Settings -> Secrets and variables -> Actions**.
2. Workflows reference secrets via the standard context:
   ```yaml
   env:
     DB_PASSWORD: ${{ secrets.DVWA_DB_PASSWORD }}
     MYSQL_ROOT_PASSWORD: ${{ secrets.DVWA_ROOT_PASSWORD }}
   ```
3. Plaintext secrets are masked automatically in all GitHub Actions console logs (`***`).

---

## 4. Secret Rotation & Revocation Protocol

If a credential is leaked or scheduled for periodic rotation:
1. **Database Password Rotation**:
   - Generate a new 32-character high-entropy secret.
   - Update `.env` locally or GitHub Actions Secrets.
   - Execute an SQL password change on MariaDB:
     ```sql
     ALTER USER 'dvwa'@'%' IDENTIFIED BY 'new_secure_password';
     FLUSH PRIVILEGES;
     ```
   - Restart the web container: `docker compose up -d --force-recreate web`.
2. **Token Revocation**:
   - Immediately revoke third-party API tokens from their respective provider dashboard (e.g. ReCAPTCHA, GitHub tokens).
   - Issue a replacement token and update the secret store.

---

## 5. Role of Gitleaks in Preventing Secret Sprawl
Gitleaks runs as an automated checkpoint:
* **Pre-commit**: Developers can run `docker run --rm -v "${PWD}:/path" zricethezav/gitleaks:latest detect --source=/path` locally.
* **Continuous Integration**: The `secrets-scan` job in `.github/workflows/devsecops.yml` analyzes every commit in the PR. If a matching secret pattern is detected, the pipeline fails immediately, blocking code merge and alerting the security team.
