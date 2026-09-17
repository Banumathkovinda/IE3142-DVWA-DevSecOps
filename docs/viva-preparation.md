# IE3142 DevSecOps Project: Viva Defense & Examination Guide

This document prepares the group to defend every architectural, cryptographic, and pipeline design decision during the viva voce examination.

---

## Topic 1: DVWA Architecture & Multi-Container Topology
* **What it is**: A two-tier containerized web application comprising an Apache+PHP 8 frontend and a MariaDB 10.11 backend.
* **Why it was used**: Provides a realistic, open-source target environment containing authentic OWASP Top 10 vulnerabilities without building mock applications.
* **How it works in this project**: The `web` container communicates with the `db` container over an isolated Docker bridge network (`dvwa-internal`) on port 3306. Port 4280 is published only to localhost (`127.0.0.1`).
* **Implementing File**: `docker-compose.yml`, `app/Dockerfile`, `app/config/config.inc.php.dist`.
* **Common Failure Scenario**: MariaDB user initialization failing because `root` access over network sockets is disabled by default in MariaDB.
* **Likely Lecturer Question**: *"Why did you use a dedicated database user instead of connecting as root?"*
* **Concise Answer**: MariaDB uses unix socket authentication for `root` by default and forbids remote TCP root logins for security. Using a dedicated `dvwa` user enforces least privilege and container separation.

---

## Topic 2: Docker, Docker Compose & Health Checks
* **What it is**: Container orchestration platform and service lifecycle manager.
* **Why it was used**: Guarantees reproducibility across laptops and CI runners while enforcing network isolation.
* **How it works in this project**: Uses `depends_on` with `condition: service_healthy` so `dvwa-web` only boots after MariaDB answers `mariadb-admin ping`.
* **Implementing File**: `docker-compose.yml`.
* **Common Failure Scenario**: Web container crashing during boot because the database is still running its initial setup scripts.
* **Likely Lecturer Question**: *"What happens if the web container starts before the database finishes initializing?"*
* **Concise Answer**: The application throws a database connection error. We prevented this race condition using Docker health checks and `condition: service_healthy`.

---

## Topic 3: Trust Boundaries & Network Segmentation
* **What it is**: Delineations where data crosses from an untrusted zone into an authenticated or internal security zone.
* **Why it was used**: Enforces defense-in-depth so a compromise of the public web tier does not grant unrestricted host or database access.
* **How it works in this project**:
  - `TB-1`: Host browser to Apache web server (127.0.0.1 loopback only).
  - `TB-2`: Web container to MariaDB (private bridge, no external port mapping for 3306).
  - `TB-3`: Container namespace to host kernel.
  - `TB-4`: GitHub Actions runner to GitHub repository and secret store.
* **Implementing File**: `docs/architecture/architecture.md`.
* **Common Failure Scenario**: Exposing database port 3306 directly to `0.0.0.0`, allowing anyone on the local Wi-Fi to query MariaDB directly.
* **Likely Lecturer Question**: *"How did you prevent external users on the local network from querying your database?"*
* **Concise Answer**: We did not publish port 3306 on the host. MariaDB is reachable solely within the internal Docker bridge network `dvwa-internal`.

---

## Topic 4: STRIDE Threat Modeling
* **What it is**: Microsoft's threat classification model (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege).
* **Why it was used**: To systematically map application-specific vulnerabilities to architectural components and controls.
* **How it works in this project**: Identifies 8 specific threats across data flows, such as SQLi exfiltration (Information Disclosure) and OS command injection (Elevation of Privilege).
* **Implementing File**: `docs/threat-model/stride.md`.
* **Common Failure Scenario**: Applying generic copy-pasted STRIDE threats that do not reflect the actual endpoints or database schema of the app.
* **Likely Lecturer Question**: *"Which STRIDE category does Command Injection fall under, and why?"*
* **Concise Answer**: Elevation of Privilege (and secondarily Denial of Service), because the attacker executes unauthorized operating system commands with the privileges of the `www-data` web server process.

---

## Topic 5: 3x3 Risk Scoring & Justification
* **What it is**: Quantitative risk prioritization based on $\text{Risk} = \text{Likelihood} \times \text{Impact}$ on a 1–3 scale.
* **Why it was used**: To distinguish catastrophic flaws (score 9) requiring blocking gates from lower-priority risks (score 1–2).
* **How it works in this project**: Pre-mitigation SQLi and Command Injection scored **9 (High)**; post-mitigation residual risk dropped to **2 (Low)**.
* **Implementing File**: `docs/risk-assessment/risk-register.md`.
* **Common Failure Scenario**: Arbitrary score assignment without written justification based on exploitability or business impact.
* **Likely Lecturer Question**: *"Why was pre-fix SQL Injection rated Likelihood 3 and Impact 3?"*
* **Concise Answer**: Likelihood is 3 because the parameter was directly exposed on an unauthenticated/low-friction HTTP form with no filtering. Impact is 3 because it permitted complete database exfiltration and authentication bypass.

---

## Topic 6: SQL Injection & Prepared Statements
* **What it is**: An injection flaw where untrusted data modifies SQL query syntax.
* **Why it was used / How remediated**: Replaced dynamic SQL string concatenation with PDO prepared statements and bound integer parameters (`$stmt->bindParam(':id', $id, PDO::PARAM_INT)`).
* **Implementing File**: `app/vulnerabilities/sqli/source/low.php`.
* **Common Failure Scenario**: Using `mysqli_real_escape_string` on numeric fields, which fails to protect against SQLi without enclosing quotes.
* **Likely Lecturer Question**: *"Why are prepared statements superior to input escaping?"*
* **Concise Answer**: Prepared statements send query structure and parameters in separate protocol packets. The database compiles the SQL logic before parameters are bound, making it mathematically impossible for parameter data to be interpreted as executable SQL syntax.

---

## Topic 7: Reflected XSS & Context-Aware Output Encoding
* **What it is**: Client-side script injection where malicious input is immediately reflected in the HTTP response.
* **Why it was used / How remediated**: Encoded user input with `htmlspecialchars($name, ENT_QUOTES | ENT_HTML5, 'UTF-8')`.
* **Implementing File**: `app/vulnerabilities/xss_r/source/low.php`.
* **Common Failure Scenario**: Relying solely on input blacklists (e.g. stripping `<script>`), which can be bypassed using `<img src=x onerror=alert(1)>`.
* **Likely Lecturer Question**: *"Can input validation replace output encoding for XSS prevention?"*
* **Concise Answer**: No. Input validation only verifies format, but output encoding ensures that characters like `<` and `>` are interpreted by the browser HTML parser strictly as display glyphs (`&lt;` and `&gt;`), completely neutralizing script execution regardless of the payload.

---

## Topic 8: Command Injection & Strict Input Whitelisting
* **What it is**: Flaw allowing arbitrary OS commands to be executed on the host/container shell.
* **Why it was used / How remediated**: Split IP address by dots (`explode`), validated that exactly 4 octets exist, verified all 4 octets are numeric integers between 0 and 255, and reconstructed a clean string passed to `escapeshellarg()`.
* **Implementing File**: `app/vulnerabilities/exec/source/low.php`.
* **Common Failure Scenario**: Blacklisting semicolons `;`, which fails because attackers can chain commands using `&&`, `||`, `|`, or newline `%0a`.
* **Likely Lecturer Question**: *"Why did you use an allow-list instead of filtering out command separators like ; and &?"*
* **Concise Answer**: Blacklists are easily bypassed through alternative shell metacharacters (`|`, `$()`, backticks, newlines). An allow-list strictly guarantees that only valid integer octets can ever reach the execution function.

---

## Topic 9: CSRF & Synchronizer Token Pattern
* **What it is**: Forcing an authenticated victim's browser to execute unauthorized state-changing requests using ambient credentials.
* **Why it was used / How remediated**: Generated session-bound anti-CSRF tokens (`generateSessionToken()`), included them in legitimate forms (`tokenField()`), and validated them server-side using `checkToken()` and `hash_equals()`.
* **Implementing File**: `app/vulnerabilities/csrf/source/low.php`, `app/vulnerabilities/csrf/index.php`.
* **Common Failure Scenario**: Using predictable tokens (e.g. MD5 of username) or performing loose string equality checks vulnerable to timing attacks.
* **Likely Lecturer Question**: *"Why did you use hash_equals() instead of the == operator to check CSRF tokens?"*
* **Concise Answer**: Standard equality operators (`==` or `===`) terminate comparison on the first mismatched byte, allowing attackers to deduce token characters through timing measurements. `hash_equals()` executes in constant time, preventing side-channel timing attacks.

---

## Topic 10: Semgrep SAST & Security Gating
* **What it is**: Fast, syntax-aware static analysis tool scanning source code patterns.
* **Why it was used**: Identifies insecure coding patterns without executing code; easily integrated into local Docker commands and GitHub Actions.
* **How it works in this project**: Scanned codebase using `p/php` and `dvwa-rules.yml`. Detected 44 findings before remediation; verified 0 findings in remediated `low.php` files.
* **Implementing File**: `security/semgrep/rules/dvwa-rules.yml`, `.github/workflows/devsecops.yml`.
* **Common Failure Scenario**: Adding `--exclude` to ignore files simply to make CI green.
* **Likely Lecturer Question**: *"How did Semgrep know that SQL injection was eliminated in your remediated file?"*
* **Concise Answer**: Semgrep analyzed the abstract syntax tree (AST) and observed that the dynamic string concatenation was replaced with a prepared statement (`$db->prepare` with parameter binding), satisfying the negative pattern match.

---

## Topic 11: Dependency / SCA Scanning (Trivy & Composer Audit)
* **What it is**: Software Composition Analysis identifying known CVEs in third-party libraries.
* **Why it was used**: Prevents vulnerable open-source dependencies (supply chain attacks) from entering production.
* **How it works in this project**: Scans `app/vulnerabilities/api/composer.lock` with `composer audit` and `trivy fs`, confirming 0 critical CVEs.
* **Implementing File**: `security/dependency/README.md`.
* **Likely Lecturer Question**: *"What is the difference between scanning composer.json and composer.lock?"*
* **Concise Answer**: `composer.json` only specifies version ranges (e.g. `^4.10`), whereas `composer.lock` records the exact resolved package hashes and transitive dependencies actually installed in the environment.

---

## Topic 12: Secrets Detection (Gitleaks)
* **What it is**: Regex and entropy-based secrets scanner for Git commits and repository files.
* **Why it was used**: Prevents credentials, private tokens, and API keys from leaking into version control.
* **How it works in this project**: Evaluates all commits; uses `.gitleaks.toml` to legitimately allowlist static educational text while blocking real credentials.
* **Implementing File**: `.gitleaks.toml`, `security/gitleaks/README.md`.
* **Likely Lecturer Question**: *"Why did you need a .gitleaks.toml allowlist?"*
* **Concise Answer**: Upstream DVWA contained an educational CSRF help snippet with a dummy hex string that matched Gitleaks' generic API key regex. We documented and allowlisted that specific documentation string to maintain security without false-positive disruptions.

---

## Topic 13: Container Image Scanning (Trivy)
* **What it is**: Vulnerability scanner for container base images and installed operating system packages.
* **Why it was used**: Catches vulnerabilities in Debian packages (`php:8-apache`) that SAST cannot detect.
* **How it works in this project**: Scans the built container image; policy fails the pipeline if any fixable critical vulnerability (`--ignore-unfixed --severity CRITICAL`) is found.
* **Implementing File**: `security/trivy/README.md`.
* **Likely Lecturer Question**: *"Why did you use --ignore-unfixed in your container gate?"*
* **Concise Answer**: Unfixed vulnerabilities are issues where upstream Debian maintainers have not yet released a patch. Blocking on unfixable CVEs causes unresolvable build deadlocks. Focusing on fixable CVEs enforces actionable remediation.

---

## Topic 14: Failed vs. Successful CI/CD Pipeline
* **What it is**: Automated security gating in GitHub Actions.
* **Why it was used**: Demonstrates that the DevSecOps pipeline actively blocks releases when security policies are breached.
* **How it works in this project**:
  - Failed Run (`demo/failed-pipeline`): An introduced raw echo triggers Semgrep rule `dvwa-reflected-xss-unescaped-echo`, exiting with code 1.
  - Success Run (`main`): All 4 remediations pass SAST, SCA, Secrets, and Container Image gates.
* **Implementing File**: `.github/workflows/devsecops.yml`, `evidence/15-pipeline-failed/`, `evidence/16-pipeline-success/`.
* **Likely Lecturer Question**: *"How did you demonstrate a pipeline failure without exposing real credentials?"*
* **Concise Answer**: We created a controlled demo branch introducing a deliberate unescaped XSS echo. Semgrep returned exit code 1 on severity ERROR, failing the job and proving the gate works cleanly.

---

## Topic 15: Secrets Management & Environment Isolation
* **What it is**: Separation of configuration and credentials from source code.
* **Why it was used**: Eliminates hardcoded passwords, enabling environment-specific secrets injection.
* **How it works in this project**: `.env` is excluded in `.gitignore`. `.env.example` provides placeholders. DVWA dynamically reads `DB_PASSWORD` and `DB_SERVER` via `getenv()` at startup.
* **Implementing File**: `.env.example`, `.gitignore`, `docs/secrets-management.md`.
* **Likely Lecturer Question**: *"Where are database passwords stored in production vs local development?"*
* **Concise Answer**: Locally, in an uncommitted `.env` file. In CI/CD or production, in encrypted GitHub Actions Secrets or cloud key vaults (like HashiCorp Vault), injected into container environment variables at runtime.
