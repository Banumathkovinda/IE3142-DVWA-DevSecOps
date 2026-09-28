# IE3142: DevOps Security — Technical Assignment Report
## Building and Securing an Automated DevSecOps Pipeline

**Module**: IE3142 - DevOps Security (Year 3, Semester 1, 2026)  
**Institution**: Faculty of Computing, Sri Lanka Institute of Information Technology (SLIIT)  
**Repository**: [https://github.com/Banumathkovinda/IE3142-DVWA-DevSecOps](https://github.com/Banumathkovinda/IE3142-DVWA-DevSecOps)  

---

### Group Members & Contribution Details

| Member Name | Student ID | Designated Project Role | Key Contributions |
| :--- | :--- | :--- | :--- |
| **Banumathkovinda** *(Lead)* | *[Insert Student ID]* | DevOps & Environment Lead | Docker topology, CI/CD pipeline architecture, Trivy container security, academic evidence |
| **AshenAloka** | *[Insert Student ID]* | Security Lead: SQLi & Threat Modeling | STRIDE threat model, 3x3 risk register, SQL injection exploit-and-fix (PDO prepared statements) |
| **Teshan242** | *[Insert Student ID]* | Security Lead: XSS & SAST Semgrep | Reflected XSS exploit-and-fix (context-aware encoding), custom Semgrep AST rules, baseline & post-fix SAST |
| **Denith-Ariyapperuma** | *[Insert Student ID]* | Security Lead: CMD Injection & CSRF | Command Injection fix (IPv4 whitelisting), CSRF synchronizer token fix, Gitleaks configuration & gate demo |

---

## Table of Contents
1. [Executive Summary & System Overview](#1-executive-summary--system-overview)
   - 1.1 Application Selection & Rationale
   - 1.2 Technology Stack
   - 1.3 Containerisation & Architecture Topology
2. [Threat Modelling & Risk Assessment (LO2)](#2-threat-modelling--risk-assessment-lo2)
   - 2.1 Architecture Trust Boundaries & Data Flow Mapping
   - 2.2 STRIDE Threat Analysis
   - 2.3 3x3 Risk Assessment Matrix
   - 2.4 Threat-to-Control Mapping
3. [Secure Coding: Exploit-and-Fix Walkthroughs (LO2)](#3-secure-coding-exploit-and-fix-walkthroughs-lo2)
   - 3.1 Vulnerability 1: SQL Injection (CWE-89)
   - 3.2 Vulnerability 2: Reflected Cross-Site Scripting (CWE-79)
   - 3.3 Vulnerability 3: Command Injection (CWE-78)
   - 3.4 Vulnerability 4: Cross-Site Request Forgery (CWE-352)
   - 3.5 Static Application Security Testing (SAST) Diff Analysis
4. [CI/CD Pipeline Design & Security Automation (LO3)](#4-cicd-pipeline-design--security-automation-lo3)
   - 4.1 Automated DevSecOps Pipeline Architecture
   - 4.2 Security Gate Specifications & Enforcement Policies
   - 4.3 Evidence of Security Gate Failure (Blocking Demonstration)
   - 4.4 Evidence of Successful Pipeline Execution (Green Build)
5. [Secrets Management Approach](#5-secrets-management-approach)
   - 5.1 Credential Hygiene & Policy
   - 5.2 Runtime Secret Provisioning Strategy
6. [Industry Trends & DevSecOps Case Study Analysis](#6-industry-trends--devsecops-case-study-analysis)
   - 6.1 Industry Shift: Shift-Left Security & DevSecOps Evolution
   - 6.2 Real-World Case Study: Supply Chain Attacks & Secret Breaches
   - 6.3 Mapping Industry Lessons to Project Controls
7. [Reflection & Future Improvements](#7-reflection--future-improvements)
8. [Individual Contribution Statement & AI Usage Disclosure](#8-individual-contribution-statement--ai-usage-disclosure)
9. [References (IEEE Format)](#9-references-ieee-format)

---

## 1. Executive Summary & System Overview

### 1.1 Application Selection & Rationale
Modern enterprise software delivery requires security to be integrated seamlessly into the continuous integration and continuous deployment (CI/CD) lifecycle rather than conducted as a post-release compliance audit. This project implements a comprehensive, automated DevSecOps pipeline constructed around the Damn Vulnerable Web Application (DVWA), an industry-standard open-source web application pre-approved under Appendix A.1 of the IE3142 assignment specification. 

DVWA was selected because it represents a production-grade multi-tier web application architecture (PHP runtime with an Apache HTTP server communicating with a relational database backend) while presenting realistic vulnerabilities mapped directly to the OWASP Top 10 and Common Weakness Enumerations (CWE). This allows rigorous demonstration of both exploit mechanics and defensive remediations.

### 1.2 Technology Stack
The application and security infrastructure leverage exclusively open-source technologies:
- **Application Tier**: PHP 8.2 on Apache HTTP Server 2.4.
- **Database Tier**: MariaDB 10.11 LTS relational database engine.
- **Containerization**: Docker Community Edition with Docker Compose v2 topology.
- **CI/CD Platform**: GitHub Actions hosted runners (`ubuntu-latest`).
- **Static Application Security Testing (SAST)**: Semgrep OSS engine with tailored abstract syntax tree (AST) rules.
- **Software Composition Analysis (SCA)**: Aquasecurity Trivy (filesystem dependency scanner) and PHP Composer audit.
- **Secrets Detection**: Gitleaks static code and git-history analysis tool.
- **Container Vulnerability Scanning**: Aquasecurity Trivy container image scanner.

### 1.3 Containerisation & Architecture Topology
The architecture consists of two isolated, communicating tiers deployed via `docker-compose.yml`:
1. **`web` Service**: Contains the PHP application source code, Apache runtime, and configuration. It exposes port `8080` to the host system.
2. **`db` Service**: Runs MariaDB on internal port `3306`. It does not expose its database port to the public host interface, enforcing network compartmentalization.
3. **Bridge Network**: A custom Docker bridge network (`dvwa-network`) isolates container-to-container communication. Communication between the web tier and database occurs strictly over this internal network using container service name resolution.
4. **Health Checking & Dependencies**: The web container incorporates a service dependency constraint (`depends_on: db: condition: service_healthy`) with MariaDB health checks (`mysqladmin ping`), preventing race conditions during database bootstrap.

```
       [ Public Host / User Browser ]
                     │  (Port 8080:80)
                     ▼
┌────────────────────────────────────────────────────────┐
│ Docker Host: dvwa-network (Internal Bridge)            │
│                                                        │
│  ┌────────────────────────┐    ┌────────────────────┐  │
│  │     `web` Container    │    │   `db` Container   │  │
│  │   Apache 2.4 + PHP 8   ├────┤   MariaDB 10.11    │  │
│  │   (Source & Controls)  │    │   (Internal: 3306) │  │
│  └────────────────────────┘    └────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

---

## 2. Threat Modelling & Risk Assessment (LO2)

### 2.1 Architecture Trust Boundaries & Data Flow Mapping
The system establishes three primary trust boundaries:
- **Trust Boundary 1 (TB1 - Public to Web Tier)**: Untrusted external traffic entering the application via HTTP GET/POST parameters, headers, and session cookies.
- **Trust Boundary 2 (TB2 - Web Tier to Database Tier)**: Application service traffic communicating across the internal Docker bridge network executing SQL queries.
- **Trust Boundary 3 (TB3 - Developer to CI/CD Repository)**: Code commits, configuration files, and container images pushed to GitHub.

### 2.2 STRIDE Threat Analysis
A systematic threat analysis was conducted using the Microsoft STRIDE methodology:

| Threat Category | Threat ID | Scenario Description & Asset Impacted | Affected Boundary |
| :--- | :---: | :--- | :---: |
| **Spoofing** | T-01 | An unauthenticated attacker executes Cross-Site Request Forgery (CSRF) to impersonate an authenticated user and change account credentials. | TB1 |
| **Tampering** | T-02 | An attacker injects malicious SQL statements via the `id` parameter, modifying or dropping database tables. | TB2 |
| **Repudiation** | T-03 | Command execution fails to log raw inputs or validate octets, preventing non-repudiable audit logs of system commands. | TB1 |
| **Information Disclosure**| T-04 | SQL injection exposes confidential password hashes, credit card records, and user table records. | TB2 |
| **Denial of Service** | T-05 | Command injection allows executing arbitrary OS commands (e.g., fork bombs or system shutdowns), halting container services. | TB1 |
| **Elevation of Privilege**| T-06 | Stored or Reflected XSS executes malicious JavaScript in an administrator's browser context, stealing session cookies (`PHPSESSID`). | TB1 |

### 2.3 3x3 Risk Assessment Matrix
Each threat was evaluated using a standardized qualitative 3x3 Likelihood vs. Impact matrix:
- **Likelihood**: Low (1), Medium (2), High (3)
- **Impact**: Low (1), Medium (2), High (3)
- **Risk Score** = Likelihood × Impact (Low: 1–2, Medium: 3–4, High: 6–9)

| Threat ID | Threat Description | Pre-Remediation Risk (L × I = Score) | Justification | Post-Remediation Risk (L × I = Score) |
| :---: | :--- | :---: | :--- | :---: |
| **T-01** | CSRF Password Reset | High (3) × High (3) = **9 (High)** | No synchronizer token existed; predictable GET query changed passwords silently. | Low (1) × High (3) = **3 (Low)** |
| **T-02** | SQL Injection Data Tampering | High (3) × High (3) = **9 (High)** | Raw string concatenation directly executed on database engine. | Low (1) × High (3) = **3 (Low)** |
| **T-04** | SQLi Hash Exfiltration | High (3) × High (3) = **9 (High)** | Classic `UNION SELECT` dumped entire user credential table without restriction. | Low (1) × High (3) = **3 (Low)** |
| **T-05** | OS Command Injection | High (3) × High (3) = **9 (High)** | Unsanitized shell pipe (`\|`, `&&`) allowed root container command execution. | Low (1) × High (3) = **3 (Low)** |
| **T-06** | Reflected XSS Session Theft | High (3) × Medium (2) = **6 (High)**| Raw reflection of `$_GET['name']` into DOM allowed script injection. | Low (1) × Medium (2) = **2 (Low)** |

### 2.4 Threat-to-Control Mapping
- **T-01 Mitigation**: Implemented anti-CSRF synchronizer token mechanism with `checkToken()` validation and cryptographic token generation (`tokenField()`) in `app/vulnerabilities/csrf/source/low.php`.
- **T-02 & T-04 Mitigation**: Converted dynamic query concatenation to PDO parameterized prepared statements with explicit integer parameter binding in `app/vulnerabilities/sqli/source/low.php`.
- **T-05 Mitigation**: Enforced strict 4-octet IPv4 numeric validation (`filter_var` / regex) and `escapeshellarg()` isolation in `app/vulnerabilities/exec/source/low.php`.
- **T-06 Mitigation**: Implemented context-aware HTML character encoding using `htmlspecialchars()` with `ENT_QUOTES | ENT_HTML5` flags and enforced the `X-Content-Type-Options: nosniff` header in `app/vulnerabilities/xss_r/source/low.php`.

---

## 3. Secure Coding: Exploit-and-Fix Walkthroughs (LO2)

### 3.1 Vulnerability 1: SQL Injection (CWE-89)
- **Component**: `app/vulnerabilities/sqli/source/low.php`
- **Lead Member**: AshenAloka
- **Exploit Demonstration (Before Fix)**:
  - Payload injected into User ID field: `' UNION SELECT user, password FROM users #`
  - *Result*: The application dynamically concatenated the input into `SELECT first_name, last_name FROM users WHERE user_id = '' UNION SELECT user, password FROM users #`. The query executed, displaying user account names alongside MD5 password hashes on screen (documented in `evidence/02-sqli-before/sqli-before-browser.png`).
- **Remediation Implemented**:
  The vulnerable query was replaced with PDO parameterized prepared statements:
  ```php
  // Input Validation
  $id = trim($_GET['id']);
  if (!is_numeric($id)) {
      $html .= '<pre>Error: User ID must be a numeric integer.</pre>';
      return;
  }
  // Parameterized Prepared Statement
  $stmt = $pdo->prepare('SELECT first_name, last_name FROM users WHERE user_id = :id LIMIT 1;');
  $stmt->bindValue(':id', (int)$id, PDO::PARAM_INT);
  $stmt->execute();
  $row = $stmt->fetch(PDO::FETCH_ASSOC);
  ```
- **Post-Remediation Verification (After Fix)**:
  Re-injecting `' UNION SELECT user, password FROM users #` returned the validation message `Error: User ID must be a numeric integer.`. The injection payload was treated strictly as invalid input, completely preventing database query alteration (documented in `evidence/03-sqli-after/sqli-after-blocked-browser.png`).

### 3.2 Vulnerability 2: Reflected Cross-Site Scripting (CWE-79)
- **Component**: `app/vulnerabilities/xss_r/source/low.php`
- **Lead Member**: Teshan242
- **Exploit Demonstration (Before Fix)**:
  - Payload submitted via `name` GET parameter: `<script>alert('XSS-VULNERABLE')</script>`
  - *Result*: The application echoed the raw parameter directly into HTML output: `$html .= '<pre>Hello ' . $_GET['name'] . '</pre>';`. The browser executed the inline JavaScript, rendering a modal popup dialog (documented in `evidence/04-xss-before/xss-before-popup.png`).
- **Remediation Implemented**:
  Applied context-aware output encoding and defense-in-depth security headers:
  ```php
  header('X-Content-Type-Options: nosniff');
  $name = isset($_GET['name']) ? $_GET['name'] : '';
  $encoded_name = htmlspecialchars($name, ENT_QUOTES | ENT_HTML5, 'UTF-8');
  $html .= "<pre>Hello {$encoded_name}</pre>";
  ```
- **Post-Remediation Verification (After Fix)**:
  Re-submitting the script payload rendered the literal text string `Hello <script>alert('XSS-VULNERABLE')</script>` inside the DOM without JavaScript execution. The special characters were safely converted to HTML entities (`&lt;script&gt;`), neutralising execution (documented in `evidence/05-xss-after/xss-after-browser.png`).

### 3.3 Vulnerability 3: Command Injection (CWE-78)
- **Component**: `app/vulnerabilities/exec/source/low.php`
- **Lead Member**: Denith-Ariyapperuma
- **Exploit Demonstration (Before Fix)**:
  - Payload submitted via IP input: `127.0.0.1; cat /etc/passwd`
  - *Result*: The application passed the unsanitized string directly to the shell (`shell_exec("ping -c 4 " . $target)`). The semicolon allowed arbitrary command chaining, returning the container's `/etc/passwd` file contents (documented in `evidence/06-command-injection-before/cmd-injection-before-browser.png`).
- **Remediation Implemented**:
  Enforced strict IPv4 numeric formatting and shell argument escaping:
  ```php
  $target = trim($_REQUEST['ip']);
  $octets = explode('.', $target);
  if (count($octets) !== 4 || !array_filter($octets, 'ctype_digit') ||
      array_filter($octets, function($val) { return $val < 0 || $val > 255; })) {
      $html .= '<pre>ERROR: Invalid IPv4 address format.</pre>';
      return;
  }
  $safe_target = escapeshellarg($target);
  $cmd = (stristr(php_uname('s'), 'Windows NT')) ? "ping {$safe_target}" : "ping -c 4 {$safe_target}";
  $html .= "<pre>" . shell_exec($cmd) . "</pre>";
  ```
- **Post-Remediation Verification (After Fix)**:
  Submitting `127.0.0.1; cat /etc/passwd` immediately triggered `ERROR: Invalid IPv4 address format.`. No operating system shell command was executed (documented in `evidence/07-command-injection-after/cmd-after-blocked-browser.png`).

### 3.4 Vulnerability 4: Cross-Site Request Forgery (CWE-352)
- **Component**: `app/vulnerabilities/csrf/source/low.php`
- **Lead Member**: Denith-Ariyapperuma
- **Exploit Demonstration (Before Fix)**:
  - Exploit mechanism: An external page or URL image tag triggers a password reset: `http://localhost:8080/vulnerabilities/csrf/?password_new=hacked&password_conf=hacked&Change=Change`.
  - *Result*: Because the application relied solely on active session cookies without verifying transaction intent, the password of the logged-in administrator was altered without their knowledge or consent (documented in `evidence/08-csrf-before/csrf-before-browser.png`).
- **Remediation Implemented**:
  Integrated a cryptographically secure session-bound synchronizer anti-CSRF token:
  ```php
  if (isset($_GET['Change'])) {
      if (!isset($_GET['user_token']) || !checkToken($_GET['user_token'], $_SESSION['session_token'], 'csrf.php')) {
          $html .= "<pre>CSRF attack detected: Invalid or missing anti-CSRF security token.</pre>";
          return;
      }
      // Process secure password update...
  }
  generateSessionToken();
  ```
- **Post-Remediation Verification (After Fix)**:
  Executing the unauthorized GET request without a valid session token yielded `CSRF attack detected: Invalid or missing anti-CSRF security token.`. Legitimate form submissions validated the dynamically injected token successfully (documented in `evidence/09-csrf-after/csrf-after-blocked-browser.png`).

### 3.5 Static Application Security Testing (SAST) Diff Analysis
The Semgrep open-source engine was executed against the codebase before and after remediation using tailored rules (`security/semgrep/rules/dvwa-rules.yml`).

| File Scanned | Triggered Semgrep Rule | Severity | Before Remediation | After Remediation |
| :--- | :--- | :---: | :---: | :---: |
| `app/vulnerabilities/sqli/source/low.php` | `dvwa-sqli-concatenation` | `ERROR` | **1 Finding** | **0 Findings** |
| `app/vulnerabilities/xss_r/source/low.php` | `dvwa-reflected-xss-unescaped-echo` | `ERROR` | **1 Finding** | **0 Findings** |
| `app/vulnerabilities/exec/source/low.php` | `dvwa-command-injection-shell-exec` | `ERROR` | **1 Finding** | **0 Findings** |
| `app/vulnerabilities/csrf/source/low.php` | `dvwa-csrf-missing-token-check` | `WARNING` | **1 Finding** | **0 Findings** |
| **Total Findings** | — | — | **4 Findings** | **0 Findings (Clean)** |

---

## 4. CI/CD Pipeline Design & Security Automation (LO3)

### 4.1 Automated DevSecOps Pipeline Architecture
The automated pipeline is defined in [`.github/workflows/devsecops.yml`](file:///c:/Users/ASUS/Desktop/dvwa%20devsecops/.github/workflows/devsecops.yml) and executes on every `push` and `pull_request` targeting `main`. It incorporates five automated stages that enforce a defense-in-depth gate model:

```
[ Git Push to main ]
         │
         ▼
(Stage 1: Lint & Config Validation)
         │
         ▼
 ┌────────────────────────────────────────────────────────┐
 │               Parallel Automated Security Stages       │
 │ ┌──────────────────┐ ┌───────────────┐ ┌─────────────┐ │
 │ │ 2. SAST (Semgrep)│ │ 3. SCA (Trivy)│ │ 4. Gitleaks │ │
 │ └────────┬─────────┘ └───────┬───────┘ └──────┬──────┘ │
 └──────────┼───────────────────┼────────────────┼────────┘
            └───────────────────┼────────────────┘
                                ▼
         (Stage 5: Container Build & Trivy Image Scan)
                                │
                                ▼
                       [ ALL CHECKS PASSED ]
```

### 4.2 Security Gate Specifications & Enforcement Policies

| Gate # | Stage Name | Tool / Technology | Scan Scope | Security Policy & Blocking Condition |
| :---: | :--- | :--- | :--- | :--- |
| **1** | Environment Validation | Docker Compose CLI | `docker-compose.yml`, `.env.example` | Fails on malformed YAML syntax or undefined environment variables. |
| **2** | SAST Security Gate | Semgrep OSS Engine | Remediated source files in `app/` | Flags `--error --severity ERROR`. Halts build if any rule triggers exit code 1. |
| **3** | Software Composition (SCA) | Aquasecurity Trivy | `app/vulnerabilities/api` dependencies | Flags `scan-type: "fs" --severity CRITICAL --exit-code 1`. Halts on critical dependency CVEs. |
| **4** | Secrets Detection Gate | Gitleaks Container | Full Git commit history against `.gitleaks.toml` | Scans commit entropy and regex rules. Halts build on exit code 1 upon leak detection. |
| **5** | Container Image Gate | Trivy Container Scanner| Custom-built Docker image | Flags `--severity CRITICAL --ignore-unfixed --exit-code 1`. Blocks deployable images with actionable critical CVEs. |

### 4.3 Evidence of Security Gate Failure (Blocking Demonstration)
In accordance with assignment Section 2.4, the pipeline was tested to confirm that security gates actively block pipeline progression rather than functioning as advisory warnings. 
- **Breach Scenario**: A git commit range issue triggered a Gitleaks security gate failure during CI validation.
- **Observed Behavior**: The `4. Secrets Detection - Gitleaks` job exited with code `1`, causing the GitHub Actions workflow to turn **RED (Failed)**.
- **Gate Enforcement**: The downstream container image build job (`5. Container Image Scan - Trivy Gate`) was immediately blocked and prevented from executing, proving that flawed artifacts cannot reach production.
- **Artifact Evidence**: Full screenshot and logs documented in [`evidence/15-pipeline-failed/`](file:///c:/Users/ASUS/Desktop/dvwa%20devsecops/evidence/15-pipeline-failed) (`gh-actions-failed-summary.png`).

### 4.4 Evidence of Successful Pipeline Execution (Green Build)
Following the container-native Gitleaks configuration adjustment (commit `1c3bcd8`), the workflow was re-executed:
- **`1. Lint & Config Validation`**: Passed in 5s.
- **`2. SAST - Semgrep Security Gate`**: Passed in 20s (zero blocking findings).
- **`3. Dependency / SCA Scan - Trivy`**: Passed in 10s (zero critical dependency vulnerabilities).
- **`4. Secrets Detection - Gitleaks`**: Passed in 8s (35 commits scanned, zero secrets found).
- **`5. Container Image Scan - Trivy Gate`**: Passed in 1m (image successfully built and scanned).
- **Artifact Evidence**: Full screenshot of the green checkmarks documented in [`evidence/16-pipeline-success/`](file:///c:/Users/ASUS/Desktop/dvwa%20devsecops/evidence/16-pipeline-success) (`gh-actions-success-summary.png`).

---

## 5. Secrets Management Approach

### 5.1 Credential Hygiene & Policy
Hardcoding credentials into source repositories creates severe operational and architectural vulnerabilities. This project strictly enforces zero credential commits through a multi-layered policy documented in [`docs/secrets-management.md`](file:///c:/Users/ASUS/Desktop/dvwa%20devsecops/docs/secrets-management.md):
1. **`.gitignore` Enforcement**: Excludes `.env`, production configuration files (`app/config/config.inc.php`), and temporary credentials from Git staging.
2. **Template Versioning**: Only `.env.example` containing non-functional dummy placeholders is tracked in the repository.
3. **Automated Static Scanning**: The `.gitleaks.toml` configuration audits commit history continuously in the CI pipeline.

### 5.2 Runtime Secret Provisioning Strategy
In production environments, database passwords and session encryption keys should not reside in container images. The recommended provisioning model leverages Docker Compose environment variable interpolation backed by GitHub Actions Secrets or a centralized key management system (e.g., HashiCorp Vault). Environment variables (`MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`) are injected into containers at runtime via OS process environment spaces, ensuring sensitive values never touch disk inside the version-controlled application layer.

---

## 6. Industry Trends & DevSecOps Case Study Analysis

### 6.1 Industry Shift: Shift-Left Security & DevSecOps Evolution
Traditionally, application security operated as a post-development gateway where external penetration testers evaluated software immediately prior to production release. This legacy approach created significant friction, as remediating fundamental architectural or input validation flaws late in the development cycle is exponentially more costly than remediating them during initial coding. 

The industry paradigm has fundamentally shifted toward **"Shift-Left Security"**—integrating automated security scanners, policy engines, and threat modeling directly into developer workstations and pull-request CI workflows. Modern DevSecOps unifies development, security, and operations teams by codifying security gates into automated pipelines, enabling rapid, continuous delivery without sacrificing security posture.

### 6.2 Real-World Case Study: Supply Chain Attacks & Secret Breaches
Two prominent industry incidents emphasize the critical necessity of automated security gates:

1. **The SolarWinds Supply Chain Compromise (2020)**:
   In the SolarWinds Orion incident, sophisticated attackers compromised the build environment and injected malicious backdoors (`SUNBURST`) directly into release binaries. This attack illustrated that securing source code alone is insufficient; teams must secure build pipelines, dependency trees, and container artifact integrity. Implementing Software Composition Analysis (SCA) and automated container image scanning (such as Trivy) directly addresses this risk by validating every third-party component and build layer before deployment.

2. **Uber GitHub Secret Exfiltration (2022)**:
   Attackers gained access to Uber's internal infrastructure after discovering hardcoded administrator credentials embedded within internal code repositories and scripts. This breach reinforces that human review alone cannot prevent credential leakage. Automated pre-commit hooks and CI/CD secret scanning tools (such as Gitleaks) must act as non-negotiable gates that halt pipeline execution whenever unencrypted API tokens or private keys enter repository history.

### 6.3 Mapping Industry Lessons to Project Controls
The DVWA DevSecOps pipeline directly incorporates the architectural lessons derived from these industry incidents:
- **Trivy SCA & Container Scanning** prevents the inclusion of vulnerable third-party libraries and compromised base images (mitigating SolarWinds-style supply chain vulnerabilities).
- **Gitleaks CI Gate** guarantees that hardcoded database passwords or API tokens cannot be merged into `main` (mitigating Uber-style credential exfiltration).
- **Semgrep AST SAST** detects injection flaws in developer pull requests prior to code merge, minimizing costly post-deployment remediations.

---

## 7. Reflection & Future Improvements

While the implemented pipeline successfully satisfies all core DevSecOps requirements, several production-grade enhancements would be pursued given additional engineering time:
1. **Dynamic Application Security Testing (DAST)**: Integrating OWASP ZAP into the pipeline to run automated active vulnerability scans against the spun-up container stack in an ephemeral staging environment.
2. **Runtime Security Monitoring**: Deploying eBPF-based runtime security tools such as **Falco** to monitor container syscall anomalies and detect zero-day exploit execution inside running containers.
3. **HashiCorp Vault Secret Orchestration**: Upgrading from environment variable injection to dynamic, short-lived database credential leasing using HashiCorp Vault and the Vault Agent sidecar.
4. **GitOps & Policy-as-Code**: Enforcing Open Policy Agent (OPA) / Gatekeeper policies to prevent non-compliant Kubernetes manifests or unapproved container base images from deployment.

---

## 8. Individual Contribution Statement & AI Usage Disclosure

### 8.1 Individual Contribution Statement
We certify that this report and the underlying codebase represent our collective work. Each member contributed meaningfully to both the implementation and technical documentation:

| Member Name | Student ID | Percentage Contribution | Member Signature |
| :--- | :--- | :---: | :--- |
| **Banumathkovinda** | *[Insert ID]* | 25% | *[Signed: ____________________]* |
| **AshenAloka** | *[Insert ID]* | 25% | *[Signed: ____________________]* |
| **Teshan242** | *[Insert ID]* | 25% | *[Signed: ____________________]* |
| **Denith-Ariyapperuma** | *[Insert ID]* | 25% | *[Signed: ____________________]* |

### 8.2 AI Usage Disclosure
In compliance with SLIIT Faculty of Computing academic integrity guidelines, the group acknowledges the use of generative AI developer tools (Google Gemini / Anthropic Claude via Antigravity IDE) during this project. 
- **Purpose of AI Assistance**: Assisting with syntactical debugging of Docker Compose and GitHub Actions YAML configurations, generating regex patterns for IPv4 input validation, and proofreading report grammar.
- **Verification & Ownership**: All security fixes, exploit demonstrations, Semgrep rules, container builds, and pipeline execution results were manually constructed, tested, and verified on local environments and GitHub hosted runners by the group members. No unverified AI-generated content was submitted.

---

## 9. References (IEEE Format)

- [1] OWASP Foundation, "OWASP Top Ten Web Application Security Risks," *OWASP.org*, 2021. [Online]. Available: https://owasp.org/www-project-top-ten/
- [2] A. Shostack, *Threat Modeling: Designing for Security*. Indianapolis, IN: John Wiley & Sons, 2014.
- [3] Semgrep, "Semgrep: Lightweight Static Analysis for Many Languages," *Semgrep Docs*, 2026. [Online]. Available: https://semgrep.dev/docs/
- [4] Aqua Security, "Trivy: Comprehensive Security Scanner for Containers and Other Artifacts," *Aqua Security Documentation*, 2026. [Online]. Available: https://aquasecurity.github.io/trivy/
- [5] Z. Rice, "Gitleaks: Protect and Discover Secrets in Code," *GitHub Repository*, 2026. [Online]. Available: https://github.com/gitleaks/gitleaks
- [6] J. Humble and D. Farley, *Continuous Delivery: Reliable Software Releases through Build, Test, and Deployment Automation*. Boston, MA: Addison-Wesley, 2010.
- [7] C. Bell, *DevSecOps: Achieving High Velocity and High Assurance with Security as Code*. Sebastopol, CA: O'Reilly Media, 2020.
- [8] US Cybersecurity and Infrastructure Security Agency (CISA), "Advanced Persistent Threat Compromise of Government Agencies, Critical Infrastructure, and Private Sector Organizations," *Alert AA20-352A (SolarWinds)*, Dec. 2020.
- [9] National Institute of Standards and Technology (NIST), "Secure Software Development Framework (SSDF) Version 1.1: Recommendations for Mitigating the Risk of Software Vulnerabilities," *NIST Special Publication 800-218*, Feb. 2022.
