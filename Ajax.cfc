<cfcomponent displayname="Ajax" hint="Global Ajax Handling" output="no">
	<cfset this.DataTables = CreateObject("component", "DataTables")>

	<cffunction name="jqdtExample" access="remote" returnformat="json" output="no">
		<cfset var args = StructCopy((StructIsEmpty(form) ? url : form))>
		<cfset var k = "">		
		<cfset StructDelete(args, 'method')>
		<cfset args.ci = ["","FooID", "BarType", "BarDate", "BarName"]>
		<cfset args.View = "view_FooBar">
		<cfset args.PK = "FooID">		
		<cfset args = this.DataTables.jqdtParseFilter(arguments, args)>
		
		<cfreturn this.DataTables.jqdtCall(argumentCollection=args)>
	</cffunction>
</cfcomponent>