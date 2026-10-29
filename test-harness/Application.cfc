/**
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
*/
component{

	// The module loaded by this test application.
	request.MODULE_NAME = "cbreinit-confirm";

	// Application settings
	this.name              = hash( getCurrentTemplatePath() );
	this.sessionManagement = true;
	this.sessionTimeout    = createTimeSpan(0,0,15,0);
    this.setClientCookies  = true;

    /**************************************
	Lucee settings
	**************************************/
	// Keep tag and function output in the response when an exception occurs.
	this.bufferOutput 					= true;
	// Do not compress responses in the test application.
	this.compression 					= false;
	// Let Lucee manage whitespace.
	this.whiteSpaceManagement 			= "smart";
	// Keep whitespace in responses from remote CFC methods.
	this.suppressRemoteComponentContent = false;

	// ColdBox application paths and keys
	COLDBOX_APP_ROOT_PATH       = getDirectoryFromPath( getCurrentTemplatePath() );
	// The web server mapping for this application.
	COLDBOX_APP_MAPPING         = "";
	COLDBOX_CONFIG_FILE 	    = "";
	COLDBOX_APP_KEY 		    = "";

	// File mappings
	this.mappings[ "/root" ] = COLDBOX_APP_ROOT_PATH;

	// Find the repository root and module path from the test application path.
	moduleRootPath 	= REReplaceNoCase( this.mappings[ "/root" ], "#request.MODULE_NAME#(\\|/)test-harness(\\|/)", "" );
	modulePath 		= REReplaceNoCase( this.mappings[ "/root" ], "test-harness(\\|/)", "" );

	// Map both names to the module under test.
	this.mappings[ "/moduleroot" ] = moduleRootPath;
	this.mappings[ "/#request.MODULE_NAME#" ] = modulePath;

	// Start ColdBox with the test application.
	public boolean function onApplicationStart(){
		application.cbBootstrap = new coldbox.system.Bootstrap( COLDBOX_CONFIG_FILE, COLDBOX_APP_ROOT_PATH, COLDBOX_APP_KEY, COLDBOX_APP_MAPPING );
		application.cbBootstrap.loadColdbox();
		return true;
	}

	// Send each request through ColdBox.
	public boolean function onRequestStart(String targetPage){

		if( url.keyExists( "fwreinit" ) ){
			if( server.keyExists( "lucee" ) ){
				pagePoolClear();
			}
		}

		// Process the request after any framework reinitialization.
		application.cbBootstrap.onRequestStart( arguments.targetPage );

		return true;
	}

	public void function onSessionStart(){
		application.cbBootStrap.onSessionStart();
	}

	public void function onSessionEnd( struct sessionScope, struct appScope ){
		arguments.appScope.cbBootStrap.onSessionEnd( argumentCollection=arguments );
	}

	public boolean function onMissingTemplate( template ){
		return application.cbBootstrap.onMissingTemplate( argumentCollection=arguments );
	}

}
