<cfcomponent displayname="Functions" hint="Generic Functions" output="no">
  <cffunction name="REFindA" access="public" returntype="array" output="yes">
  	<cfargument name="regex" type="string" required="yes">
  	<cfargument name="str" type="string" required="yes">
  	<cfset var result = []>
  	<cfset var r = REFind(arguments.regex, arguments.str, 1, true)>
  	<cfset var start = (r.len[1]+r.pos[1])>
  	<cfset var i = 0>
  	
  	<cfloop condition="r.pos[1]">	
  		<cfloop from="2" to="#ArrayLen(r.len)#" index="i">
  			<cfset ArrayAppend(result, Mid(arguments.str, r.pos[i], r.len[i]))>
  		</cfloop>
  		<cfset r = REFind(arguments.regex, arguments.str, start, true)>
  		<cfset start = (r.len[1]+r.pos[1])>	
  	</cfloop>
  	
  	<cfreturn result>
  </cffunction>
</cfcomponent>
