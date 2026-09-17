# Evidence 09 - Cross-Site Request Forgery (After Remediation)

## 1. Remediation Strategy & Secure Code Design
The vulnerability was remediated by implementing cryptographically secure anti-CSRF token verification and token synchronization:
1. **Synchronizer Token Pattern**:
   - Each active session generates a pseudo-random session token via `generateSessionToken()`.
   - The token is placed into legitimate forms via hidden input field: `<input type='hidden' name='user_token' value='...' />`.
2. **Server-Side Validation with Constant-Time Comparison**:
   - The backend checks `user_token` against `$_SESSION['session_token']` using PHP's `hash_equals()`.
   - If missing, mismatched, or empty, the request is immediately rejected with `ERROR: CSRF token is missing or invalid. Action blocked.`
3. **Token Regeneration**:
   - A fresh session token is generated via `generateSessionToken()` after every state-changing request to prevent token reuse.
4. **Parameterized Update**:
   - The database update utilizes PDO prepared statements for defense-in-depth against SQL injection.

## 2. Remediated Code (`app/vulnerabilities/csrf/source/low.php`)
```php
<?php

if( isset( $_GET[ 'Change' ] ) ) {
    // Security Control 1: Cryptographic Anti-CSRF Token Validation
    $userToken = array_key_exists( 'user_token', $_REQUEST ) ? $_REQUEST[ 'user_token' ] : '';
    $sessionToken = array_key_exists( 'session_token', $_SESSION ) ? $_SESSION[ 'session_token' ] : '';

    // Enforce presence and constant-time string comparison
    if( empty( $userToken ) || empty( $sessionToken ) || !hash_equals( $sessionToken, $userToken ) ) {
        $html .= "<pre>ERROR: CSRF token is missing or invalid. Action blocked.</pre>";
    } else {
        $pass_new  = $_GET[ 'password_new' ];
        $pass_conf = $_GET[ 'password_conf' ];

        if( $pass_new == $pass_conf ) {
            // Security Control 2: Parameterized database update
            global $db;
            $pass_hash = md5( $pass_new );
            $current_user = dvwaCurrentUser();

            $stmt = $db->prepare( 'UPDATE users SET password = :password WHERE user = :user;' );
            $stmt->bindParam( ':password', $pass_hash, PDO::PARAM_STR );
            $stmt->bindParam( ':user', $current_user, PDO::PARAM_STR );
            $stmt->execute();

            $html .= "<pre>Password Changed.</pre>";
        } else {
            $html .= "<pre>Passwords did not match.</pre>";
        }
    }
}

// Security Control 3: Generate fresh anti-CSRF token
generateSessionToken();

?>
```

## 3. Post-Fix Verification: Identical Attack Payload
The exact identical forged GET request used in the pre-fix attack was re-submitted without an anti-CSRF token.

### Verification Results
* **Forged Request (No Token)**:
  `http://127.0.0.1:4280/vulnerabilities/csrf/?password_new=hacked123&password_conf=hacked123&Change=Change`
* **Server Response**:
  ```html
  <pre>ERROR: CSRF token is missing or invalid. Action blocked.</pre>
  ```
* **Forged Request (Guessed / Fake Token)**:
  `...&user_token=attacker_guessed_token&Change=Change`
  ```html
  <pre>ERROR: CSRF token is missing or invalid. Action blocked.</pre>
  ```
* **Legitimate Workflow (Valid Token)**:
  Submitting legitimate request with the valid session token succeeds:
  ```html
  <pre>Password Changed.</pre>
  ```

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `csrf-after-blocked-browser.png`: Browser view showing the forged GET URL resulting in "ERROR: CSRF token is missing or invalid. Action blocked."
- `csrf-after-legitimate-browser.png`: Browser view showing legitimate password change succeeding with hidden anti-CSRF token field visible in DevTools inspector.
