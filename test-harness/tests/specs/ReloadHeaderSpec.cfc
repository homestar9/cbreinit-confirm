/**
 * The harness app over HTTP (the header is only visible in a real response): the request that
 * reinitialises it gets the header the harness configures (X-Harness-Reloaded: reloaded), other
 * requests, a request with a wrong password and a response replayed from the event cache do not.
 */
component extends="testbox.system.BaseSpec" {

	variables.HEADER   = "X-Harness-Reloaded";
	variables.PASSWORD = "harness-pw";
	variables.VALUE    = "reloaded";

	function beforeAll(){
		variables.base = "http://" & cgi.server_name & ":" & cgi.server_port & "/index.cfm";
		// the app's first request loads it too: get that out of the way
		send( base );
	}

	function run(){
		describe( "cbreinit-confirm", function(){
			it( "sends nothing on an ordinary request", function(){
				var r = send( base );
				expect( r.status ).toBe( 200 );
				expect( r.headers ).notToHaveKey( HEADER );
			} );

			it( "sends the header to the request that reinitialised the app, once", function(){
				var r = send( base & "?fwreinit=" & PASSWORD );
				expect( r.status ).toBe( 200 );
				expect( r.headers[ HEADER ] ?: "" ).toBe( VALUE );
				expect( send( base ).headers ).notToHaveKey( HEADER, "the next request did not reload" );
			} );

			it( "sends the header for a reinit posted as a form field", function(){
				var r = send( base, { "fwreinit" : PASSWORD } );
				expect( r.status ).toBe( 200 );
				expect( r.headers[ HEADER ] ?: "" ).toBe( VALUE );
			} );

			it( "does not replay the header from ColdBox's event cache", function(){
				// main.cached leaves fwreinit out of its cache key, so the reinit caches the
				// response the next request gets
				var reinit = send( base & "/main/cached?fwreinit=" & PASSWORD );
				expect( reinit.headers[ HEADER ] ?: "" ).toBe( VALUE );
				var r = send( base & "/main/cached" );
				expect( r.status ).toBe( 200 );
				expect( r.headers[ "x-coldbox-cache-response" ] ?: "" ).toBe(
					"true",
					"served from the event cache"
				);
				expect( r.headers ).notToHaveKey( HEADER );
			} );

			it( "sends nothing when the password is wrong: ColdBox answers 200 but reloads nothing", function(){
				var r = send( base & "?fwreinit=wrong" );
				expect( r.status ).toBe( 200 );
				expect( r.headers ).notToHaveKey( HEADER );
			} );
		} );
	}

	/**
	 * GET `target`, or POST `fields` to it. Returns { status, headers }, each header by name with
	 * its first value.
	 */
	private struct function send( required string target, struct fields = {} ){
		var method = structIsEmpty( arguments.fields ) ? "GET" : "POST";
		cfhttp(
			url      = arguments.target,
			method   = method,
			redirect = false,
			result   = "local.res"
		) {
			for ( var f in fields ) {
				cfhttpparam(
					type  = "formfield",
					name  = f,
					value = fields[ f ]
				);
			}
		}
		var headers = {};
		for ( var name in local.res.responseHeader ) {
			var value       = local.res.responseHeader[ name ];
			headers[ name ] = isStruct( value ) ? value[ 1 ] : value;
		}
		return { status : val( local.res.statusCode ), headers : headers };
	}

}
