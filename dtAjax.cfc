<cfcomponent displayname="dtAjax" hint="DataTables Ajax Handling" output="no" extends="DataTables">
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