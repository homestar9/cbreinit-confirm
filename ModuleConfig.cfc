/**
 * Tells the request that reinitialised a ColdBox app that the reload happened, with a response
 * header (by default `X-Fwreinit: true`).
 *
 * ColdBox reloads inside the request that sent `fwreinit`, before it handles that request, and
 * this module's onLoad() runs during that load. onLoad() leaves a flag in the request scope; the
 * ReloadConfirmation interceptor sends the header on `preProcess`, which runs only once the load
 * has succeeded. Other requests, and a request with a wrong reinit password (which reloads
 * nothing), never get the header.
 */
component {

	// Module details
	this.title       = "cbreinit-confirm";
	this.author      = "Angry Sam Productions, Inc.";
	this.webURL      = "https://github.com/homestar9/cbreinit-confirm";
	this.description = "Sends a response header from the request that reinitialised a ColdBox app, so a deploy tool can confirm the reload.";
	this.version     = readPackageVersion();

	// WireBox model namespace
	this.modelNamespace = "cbreinit-confirm";

	// CFML mapping
	this.cfmapping = "cbreinit-confirm";

	// This module has no runtime dependencies.
	this.dependencies = [];

	/**
	 * Set the module's default settings and register its interceptor.
	 */
	function configure(){
		variables.settings = {
			// The response header sent by the request that reloaded the app. Letters, digits and
			// "-"; any other name sends nothing.
			headerName  : "X-Fwreinit",
			// Its value. Control characters are removed.
			headerValue : "true"
		};

		// ColdBox adds "@cbreinit-confirm" to each registered name.
		interceptors = [
			{
				class : "cbreinit-confirm.interceptors.ReloadConfirmation",
				name  : "ReloadConfirmation"
			}
		];
	}

	/**
	 * Runs while ColdBox loads, in the request that started the load: a reinit, or the app's first
	 * request.
	 */
	function onLoad(){
		// ReloadConfirmation reads and clears this key
		request.cbReinitConfirmLoaded = true;
	}

	/**
	 * Run after ColdBox stops and unregisters the module.
	 */
	function onUnload(){
	}

	/**
	 * Reads the module version from box.json, so a release bump changes it in one place.
	 * ColdBox reads this.version before configure(), so this method runs early.
	 * Returns an empty string when box.json cannot be read.
	 */
	private string function readPackageVersion(){
		try {
			var boxJsonPath = getDirectoryFromPath( getCurrentTemplatePath() ) & "box.json";

			if ( !fileExists( boxJsonPath ) ) {
				return "";
			}

			var boxJson = deserializeJSON( fileRead( boxJsonPath ) );

			return boxJson.keyExists( "version" ) ? boxJson.version : "";
		} catch ( any e ) {
			return "";
		}
	}

}
