<?php

// Security Control: Do not disable browser XSS protections
header( "X-Content-Type-Options: nosniff" );

// Is there any input?
if( array_key_exists( "name", $_GET ) && $_GET[ 'name' ] != NULL ) {
	// Security Control: Context-aware HTML entity output encoding
	// Converts special characters (<, >, &, ", ') to corresponding HTML entities
	$name = htmlspecialchars( $_GET[ 'name' ], ENT_QUOTES | ENT_HTML5, 'UTF-8' );

	// Feedback for end user - safely rendered as literal text
	$html .= "<pre>Hello {$name}</pre>";
}

?>
