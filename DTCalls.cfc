<cfcomponent displayname="DTCalls" hint="Handle DataTables Requests" output="no" extends="DataTables">
	<cffunction name="fooBar" access="remote" returnformat="json" output="no">
		<cfset parseRequest(arguments)>
		<cfset ParseFilter(arguments)>
		<cfset arguments["ci"] = ["Foo","Bar",""]>
		<cfset arguments["view"] = "vw_FooBar">
		<cfset arguments.ext = ["ExtraBar"]>
		<cfset arguments.PK = "FooID">
		
		<cfreturn super.processCall(argumentCollection=arguments)>
	</cffunction>
	
	<cffunction name="jqdtExample" access="remote" returnformat="json" output="no">
		<cfset var args = StructCopy((StructIsEmpty(form) ? url : form))>
		<cfset var k = "">		
		<cfset StructDelete(args, 'method')>
		<cfset args.ci = ["","FooID", "BarType", "BarDate", "BarName"]>
		<cfset args.View = "view_FooBar">
		<cfset args.PK = "FooID">		
		<cfset args = super.jqdtParseFilter(arguments, args)>
		
		<cfreturn super.jqdtCall(argumentCollection=args)>
	</cffunction>
</cfcomponent>
