<?php

if( isset( $_REQUEST[ 'Submit' ] ) ) {
	// Get input
	$id = $_REQUEST[ 'id' ];

	// Security Control 1: Validate input data type (must be integer)
	if( is_numeric( $id ) ) {
		$id = intval( $id );

		switch ($_DVWA['SQLI_DB']) {
			case MYSQL:
				// Security Control 2: Parameterized prepared statement using PDO
				global $db;
				$stmt = $db->prepare( 'SELECT first_name, last_name FROM users WHERE user_id = :id LIMIT 1;' );
				$stmt->bindParam( ':id', $id, PDO::PARAM_INT );
				$stmt->execute();

				// Get results
				while( $row = $stmt->fetch() ) {
					// Security Control 3: Output encoding for defense in depth
					$first = htmlspecialchars( $row[ 'first_name' ], ENT_QUOTES, 'UTF-8' );
					$last  = htmlspecialchars( $row[ 'last_name' ], ENT_QUOTES, 'UTF-8' );

					// Feedback for end user
					$html .= "<pre>ID: {$id}<br />First name: {$first}<br />Surname: {$last}</pre>";
				}
				break;

			case SQLITE:
				global $sqlite_db_connection;

				$stmt = $sqlite_db_connection->prepare( 'SELECT first_name, last_name FROM users WHERE user_id = :id LIMIT 1;' );
				$stmt->bindValue( ':id', $id, SQLITE3_INTEGER );
				$results = $stmt->execute();

				if ($results) {
					while ($row = $results->fetchArray()) {
						$first = htmlspecialchars( $row[ 'first_name' ], ENT_QUOTES, 'UTF-8' );
						$last  = htmlspecialchars( $row[ 'last_name' ], ENT_QUOTES, 'UTF-8' );
						$html .= "<pre>ID: {$id}<br />First name: {$first}<br />Surname: {$last}</pre>";
					}
				}
				break;
		}
	} else {
		// Input was not numeric - reject cleanly without executing SQL
		$html .= '<pre>ERROR: Invalid User ID format. ID must be an integer.</pre>';
	}
}

?>
