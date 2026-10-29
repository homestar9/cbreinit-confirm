/**
 * Renders the test application's home page, and a cached page for the event-cache spec.
 */
component{

	any function index( event,rc, prc ){
		event.setView( "main/index" );
	}

	/**
	 * Cached, with fwreinit left out of the cache key: a reinit and a plain request share one
	 * cache entry, the worst case for a header leaking from one to the other.
	 */
	any function cached( event, rc, prc ) cache="true" cacheTimeout="5" cacheExclude="fwreinit"{
		return "cached";
	}

}
