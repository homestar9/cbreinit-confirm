component extends="coldbox.system.ioc.config.Binder"{

	/**
	 * Configure WireBox for the test application.
	 */
	function configure(){

		// WireBox settings
		wireBox = {
			// Store the WireBox injector in the application scope.
			scopeRegistration = {
				enabled = true,
				scope   = "application", // server, cluster, session, application
				key		= "wireBox"
			},

			// Custom dependency injection namespaces
			customDSL = {
				// Example: namespace = "mapping name"
			},

			// Custom storage scopes
			customScopes = {
				// Example: annotationName = "mapping name"
			},

			// Packages to scan
			scanLocations = [],

			// Packages that stop recursive scanning
			stopRecursions = [],

			// Optional parent injector object
			parentInjector = "",

			// Event listeners, created in this order
			listeners = [
				// { class="", name="", properties={} }
			]
		};

		// This test application does not add custom bindings.
	}

}
