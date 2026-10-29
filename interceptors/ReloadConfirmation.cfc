/**
 * Sends the confirmation header on `preProcess` when ModuleConfig.onLoad() flagged this request:
 * the app loaded in this request and the load succeeded. The flag is cleared, so the header goes
 * out once even when the request runs more events.
 */
component {

	property name="settings" inject="coldbox:moduleSettings:cbreinit-confirm";

	function preProcess( event, data ){
		if ( !structKeyExists( request, "cbReinitConfirmLoaded" ) ) {
			return;
		}
		structDelete( request, "cbReinitConfirmLoaded" );
		var name = toString( variables.settings.headerName ?: "" );
		// a bad name would break the response; send nothing instead
		if ( !reFind( "^[A-Za-z0-9-]{1,100}$", name ) ) {
			return;
		}
		// a CR or LF would end the header and start another. An explicit range, which every
		// engine's regex flavour reads the same way
		var value = reReplace(
			toString( variables.settings.headerValue ?: "" ),
			"[\x00-\x1F\x7F]",
			"",
			"all"
		);
		// cfheader, not event.setHTTPHeader(): the event cache stores headers set on the event and
		// replays them on later requests that never reloaded anything
		cfheader( name = name, value = value );
	}

}
