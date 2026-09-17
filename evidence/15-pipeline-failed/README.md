# Evidence 15 - Controlled Security Gate Failure Demonstration

## 1. Objective & Methodology
DevSecOps pipelines must be able to detect real security flaws and actively block pull requests and builds from progressing when thresholds are violated.

To demonstrate a genuine, verifiable security gate failure without exposing real credentials or breaking main, a controlled demonstration branch `demo/failed-pipeline` is prepared.

---

## 2. Failure Scenario 1: SAST Security Gate Breach (Semgrep)

### 1. What was introduced?
A deliberate unescaped input reflection was introduced into `app/vulnerabilities/xss_r/source/low.php`:
```diff
- $name = htmlspecialchars( $_GET[ 'name' ], ENT_QUOTES | ENT_HTML5, 'UTF-8' );
- $html .= "<pre>Hello {$name}</pre>";
+ $html .= '<pre>Hello ' . $_GET['name'] . '</pre>';
```

### 2. Which scanner detected it?
* **Scanner**: Semgrep SAST
* **Triggered Rule**: `dvwa-reflected-xss-unescaped-echo`
* **Rule Severity**: `ERROR`

### 3. Exact Security Threshold & Policy
In `.github/workflows/devsecops.yml`:
```yaml
run: |
  docker run --rm -v "${{ github.workspace }}:/src" returntocorp/semgrep semgrep scan \
    --config /src/security/semgrep/rules/dvwa-rules.yml \
    --error \
    --severity ERROR \
    /src/app/vulnerabilities/xss_r/source/low.php
```
Policy: Flag `--error --severity ERROR` causes Semgrep to return exit code `1` whenever an `ERROR`-level vulnerability is detected in the scanned file.

### 4. Why the job failed?
Semgrep detected untrusted user input directly echoed into HTML without `htmlspecialchars` encoding. Semgrep emitted a blocking finding and exited with return code `1`. The GitHub Actions step failed, setting the workflow status to `FAIL` (Red Cross) and blocking downstream container build jobs.

### 5. Remediation
Reverted the unescaped echo and restored context-aware output encoding:
```php
$name = htmlspecialchars( $_GET[ 'name' ], ENT_QUOTES | ENT_HTML5, 'UTF-8' );
$html .= "<pre>Hello {$name}</pre>";
```

### 6. Next Successful Run
On the next commit, Semgrep reported `0 findings (0 blocking)` and exited with code `0`. The pipeline turned GREEN.

---

## 3. Failure Scenario 2: Secrets Scanning Gate Breach (Gitleaks)

### 1. What was introduced?
A dummy, non-sensitive fake API token was added in a test file:
```text
FAKE_AWS_KEY = "AKIAIOSFODNN7EXAMPLE12"
```

### 2. Which scanner detected it?
* **Scanner**: Gitleaks Secrets Detector
* **Triggered Rule**: `aws-access-token`
* **Commit**: Tagged on demo branch `demo/failed-pipeline`

### 3. Exact Security Threshold & Policy
Gitleaks policy enforces zero untracked credentials. Detection of any matching entropy pattern returns exit code `1`.

### 4. Why the job failed?
Gitleaks blocked the push and halted the CI pipeline with return code `1`.

### 5. Remediation
Removed the dummy key, committed the clean state, and verified `0 leaks found`.

---

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `gh-actions-failed-summary.png`: GitHub Actions summary page showing the red `X` and failed `sast-scan` or `secrets-scan` job.
- `gh-actions-failed-logs.png`: Terminal logs of the failed GitHub Actions step showing Semgrep or Gitleaks exiting with code 1.
