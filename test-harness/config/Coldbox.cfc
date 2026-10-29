component{

	// Configure the ColdBox test application.
	function configure(){

		// ColdBox settings
		coldbox = {
			// Application
			appName 				= "Module Tester",

			// Development
			// A password, so the specs can show a wrong one reloads nothing and sends no header
			reinitPassword			= "harness-pw",
			handlersIndexAutoReload = true,
			modulesExternalLocation = [],

			// Lifecycle events
			defaultEvent			= "",
			requestStartHandler		= "",
			requestEndHandler		= "",
			applicationStartHandler = "",
			applicationEndHandler	= "",
			sessionStartHandler 	= "",
			sessionEndHandler		= "",
			missingTemplateHandler	= "",

			// Errors
			exceptionHandler		= "",
			onInvalidEvent			= "",
			customErrorTemplate 	= "/coldbox/system/exceptions/Whoops.cfm",

			// Caching
			handlerCaching 			= false,
			// On, so the specs can show a cached response never replays the header
			eventCaching			= true
		};

		// Use the development environment for local test hosts.
		environments = {
			development = "localhost,127\.0\.0\.1"
		};

		// Module loading
		modules = {
			// An empty include list loads every module.
			include = [],
			// An empty exclude list skips no modules.
			exclude = []
		};

		// Module settings
		moduleSettings = {
			// The specs read the header the harness sends from here. The value has letters
			// ("r", "l") that a misread control-character pattern could strip.
			"cbreinit-confirm" : {
				headerName  : "X-Harness-Reloaded",
				headerValue : "reloaded"
			}
		};

		// Register application interceptors in order. This harness does not add any.
		interceptors = [
		];

		// Logging
		logBox = {
			// Log destinations
			appenders = {
				myConsole : { class : "ConsoleAppender" },
				files : {
					class="RollingFileAppender",
					properties = {
						filename = "tester", filePath="/#appMapping#/logs"
					}
				}
			},
			// Root logger
			root = { levelmax="DEBUG", appenders="*" },
			// Framework log level
			info = [ "coldbox.system" ]
		};

	}

	/**
	 * Load the module after ColdBox finishes its first setup stage. This still runs inside the
	 * load, so the module's onLoad() runs in the request that started it, as in an app.
	 */
	function afterAspectsLoad( event, interceptData, rc, prc ){

		controller.getModuleService()
			.registerAndActivateModule(
				moduleName 		= request.MODULE_NAME,
				invocationPath 	= "moduleroot"
			);

		// Reload the renderer so it can use any helpers from the module.
        controller.getRenderer().startup()
		// Reload interceptors so they can use any new helper methods.
        controller.getInterceptorService().announce( "cbLoadInterceptorHelpers" )
	}

}
