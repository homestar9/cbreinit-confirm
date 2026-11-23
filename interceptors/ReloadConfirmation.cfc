/**
 * Sends the confirmation header on `preProcess` when ModuleConfig.onLoad() flagged this request:
 * the app loaded in this request and the load succeeded. The flag is cleared, so the header goes
 * out once even when the request runs more events. A request that sent the reinit key but loaded
 * nothing (a wrong password) gets `rejectedValue` instead, when that is set.
 */
component {

	property name="settings" inject="coldbox:moduleSettings:cbreinit-confirm";

	function preProcess( event, data ){
		var loaded = structKeyExists( request, "cbReinitConfirmLoaded" );
		structDelete( request, "cbReinitConfirmLoaded" );
		// loaded comes first: after a successful load ColdBox removes the reinit key from url but
		// leaves it in form, so a reinit posted as a form field still carries the key here
		var raw = "";
		if ( loaded ) {
			raw = variables.settings.headerValue ?: "";
		} else {
			// url and form, as ColdBox's isFWReinit() reads them. Apps can rename the key
			var key = getSetting( "reinitKey", "fwreinit" );
			if ( !structKeyExists( url, key ) && !structKeyExists( form, key ) ) {
				return;
			}
			raw = variables.settings.rejectedValue ?: "";
		}
		var name = toString( variables.settings.headerName ?: "" );
		// a bad name would break the response; send nothing instead
		if ( !reFind( "^[A-Za-z0-9-]{1,100}$", name ) ) {
			return;
		}
		// a CR or LF would end the header and start another. An explicit range, which every
		// engine's regex flavour reads the same way
		var value = reReplace( toString( raw ), "[\x00-\x1F\x7F]", "", "all" );
		// an empty rejectedValue means it is off
		if ( !loaded && !len( value ) ) {
			return;
		}
		// cfheader, not event.setHTTPHeader(): the event cache stores headers set on the event and
		// replays them on later requests that never reloaded anything
		cfheader( name = name, value = value );
	}

}
