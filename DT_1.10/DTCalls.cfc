<cfcomponent displayname="DTCalls" hint="Handle DataTables Requests" output="no" extends="DataTables">
	<cffunction name="fooBar" access="remote" returnformat="json" output="no">
		<cfset parseRequest(arguments)>
		<cfset ParseFilter(arguments)>
		<cfset arguments["ci"] = ["Foo","Bar",""]>
		<cfset arguments["view"] = "vw_FooBar">
		<cfset arguments.ext = ["ExtraBar"]>
		<cfset arguments.PK = "FooID">
		
		<cfreturn processCall(argumentCollection=arguments)>
	</cffunction>
</cfcomponent>
