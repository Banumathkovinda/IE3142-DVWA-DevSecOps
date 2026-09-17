<?php

if( isset( $_GET[ 'Change' ] ) ) {
	// Security Control 1: Cryptographic Anti-CSRF Token Validation
	// Safely retrieve token avoiding PHP 8 undefined array key warnings
	$user_token = array_key_exists( 'user_token', $_REQUEST ) ? $_REQUEST[ 'user_token' ] : '';
	$session_token = array_key_exists( 'session_token', $_SESSION ) ? $_SESSION[ 'session_token' ] : '';

	// Enforce anti-CSRF token verification
	checkToken( $user_token, $session_token, 'index.php' );

	// Get input
	$pass_new  = $_GET[ 'password_new' ];
	$pass_conf = $_GET[ 'password_conf' ];

	// Do the passwords match?
	if( $pass_new == $pass_conf ) {
		// Security Control 2: Parameterized query for database update
		global $db;
		$pass_hash = md5( $pass_new );
		$current_user = dvwaCurrentUser();

		$stmt = $db->prepare( 'UPDATE users SET password = :password WHERE user = :user;' );
		$stmt->bindParam( ':password', $pass_hash, PDO::PARAM_STR );
		$stmt->bindParam( ':user', $current_user, PDO::PARAM_STR );
		$stmt->execute();

		// Feedback for the user
		$html .= "<pre>Password Changed.</pre>";
	}
	else {
		// Issue with passwords matching
		$html .= "<pre>Passwords did not match.</pre>";
	}
}

// Security Control 3: Generate fresh anti-CSRF token bound to current session
generateSessionToken();

?>
