<?php

if( isset( $_POST[ 'Submit' ]  ) ) {
	// Get input
	$target = trim( $_REQUEST[ 'ip' ] );
	$target = stripslashes( $target );

	// Security Control 1: Strict Allow-list Validation (IPv4 4-octet structure)
	$octet = explode( ".", $target );

	// Verify exactly 4 octets and each octet is an integer within 0-255
	if( ( sizeof( $octet ) == 4 ) &&
		is_numeric( $octet[0] ) && is_numeric( $octet[1] ) &&
		is_numeric( $octet[2] ) && is_numeric( $octet[3] ) &&
		( intval($octet[0]) >= 0 && intval($octet[0]) <= 255 ) &&
		( intval($octet[1]) >= 0 && intval($octet[1]) <= 255 ) &&
		( intval($octet[2]) >= 0 && intval($octet[2]) <= 255 ) &&
		( intval($octet[3]) >= 0 && intval($octet[3]) <= 255 ) ) {

		// Security Control 2: Reconstruct clean IP strictly from sanitized integers
		$target = intval($octet[0]) . '.' . intval($octet[1]) . '.' . intval($octet[2]) . '.' . intval($octet[3]);

		// Security Control 3: Safe argument escaping using escapeshellarg()
		if( stristr( php_uname( 's' ), 'Windows NT' ) ) {
			// Windows
			$cmd = shell_exec( 'ping  ' . escapeshellarg( $target ) );
		}
		else {
			// *nix
			$cmd = shell_exec( 'ping  -c 4 ' . escapeshellarg( $target ) );
		}

		// Security Control 4: Contextual HTML output encoding
		$html .= "<pre>" . htmlspecialchars( $cmd, ENT_QUOTES, 'UTF-8' ) . "</pre>";
	}
	else {
		// Input contained non-numeric characters, metacharacters, or invalid structure
		$html .= '<pre>ERROR: You have entered an invalid IP address format.</pre>';
	}
}

?>
