# Evidence 03 - SQL Injection (After Remediation)

## 1. Remediation Strategy & Secure Code Design
The vulnerability was remediated by implementing a multi-tier defense:
1. **Strict Input Validation**: Validates that `$id` is an integer using `is_numeric()` and `intval()`. Non-numeric input is rejected before query execution.
2. **Parameterized Prepared Statements (PDO)**: Uses `$db->prepare()` with explicit parameter binding (`$stmt->bindParam(':id', $id, PDO::PARAM_INT)`). The SQL query structure and the user parameter are transmitted separately to the MariaDB engine, making it mathematically impossible for user input to modify query grammar.
3. **Contextual Output Encoding**: Encodes dynamic output using `htmlspecialchars()` to provide defense-in-depth against stored script injection.

## 2. Remediated Code (`app/vulnerabilities/sqli/source/low.php`)
```php
<?php

if( isset( $_REQUEST[ 'Submit' ] ) ) {
    $id = $_REQUEST[ 'id' ];

    // Security Control 1: Input Data Type Validation
    if( is_numeric( $id ) ) {
        $id = intval( $id );

        switch ($_DVWA['SQLI_DB']) {
            case MYSQL:
                // Security Control 2: Parameterized Prepared Statement
                global $db;
                $stmt = $db->prepare( 'SELECT first_name, last_name FROM users WHERE user_id = :id LIMIT 1;' );
                $stmt->bindParam( ':id', $id, PDO::PARAM_INT );
                $stmt->execute();

                while( $row = $stmt->fetch() ) {
                    // Security Control 3: Output Encoding
                    $first = htmlspecialchars( $row[ 'first_name' ], ENT_QUOTES, 'UTF-8' );
                    $last  = htmlspecialchars( $row[ 'last_name' ], ENT_QUOTES, 'UTF-8' );
                    $html .= "<pre>ID: {$id}<br />First name: {$first}<br />Surname: {$last}</pre>";
                }
                break;
        ...
    } else {
        $html .= '<pre>ERROR: Invalid User ID format. ID must be an integer.</pre>';
    }
}
?>
```

## 3. Post-Fix Verification: Identical Attack Payload
The exact identical payload used during the pre-fix test (`1' OR '1'='1`) was submitted to the remediated endpoint.

### Verification Results
* **Endpoint**: `http://127.0.0.1:4280/vulnerabilities/sqli/?id=1%27+OR+%271%27%3D%271&Submit=Submit`
* **Server Response**:
  ```html
  <pre>ERROR: Invalid User ID format. ID must be an integer.</pre>
  ```
* **Integrity Status**: Zero unauthorized database records leaked; SQL injection completely neutralized.
* **Legitimate Functionality**: Submitting valid integer `id=1` returns:
  ```html
  <pre>ID: 1<br />First name: admin<br />Surname: admin</pre>
  ```

## 4. Manual Screenshot Checklist
Capture and place the following screenshots in this directory:
- `sqli-after-blocked-browser.png`: Browser view showing the identical payload `1' OR '1'='1` resulting in "ERROR: Invalid User ID format. ID must be an integer."
- `sqli-after-legitimate-browser.png`: Browser view showing legitimate ID `1` returning the single expected record.
